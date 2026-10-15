classdef TestParametricSeedProject < matlab.unittest.TestCase
    properties (TestParameter)
        Revision={"WHEELBASE","TRACK","RADIUS","UPRIGHT","UBJ","LBJ","UCA","LCA","TIE","SYMMETRY","DESCRIPTION","PARAM_DESCRIPTION","MASS"}
        Attack={"PLAN","OPTIONS","QUALITY","CONVERGENCE","SOURCE_GEOMETRY","SOURCE_GRID","SEED_IDENTITY","CONTEXT","REVISION","NOMINAL","PROVENANCE","BINDING"}
        Missing={"WB","TRACK","UPRIGHT","UCA","FAMILY","PENDING"}
    end
    methods (TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples'));
        end
    end
    methods (Test)
        function incompleteProjectRoundTripAndIncrementalReadiness(t,Missing)
            f=parametricSeedFixture('FRONT'); cd=f.concept.definitionSI; dd=f.definition.definitionSI;
            switch Missing
                case "WB", cd.parameters=cd.parameters(~cellfun(@(p)p.id=="WHEELBASE",cd.parameters));
                case "TRACK", cd.parameters=cd.parameters(~cellfun(@(p)p.id=="FRONT_TRACK",cd.parameters));
                case {"UPRIGHT","UCA"}
                    prefix="UBJ_"; if Missing=="UCA", prefix="UCA_"; end
                    dd.parameters=dd.parameters(~cellfun(@(p)startsWith(p.definitionSI.id,prefix),dd.parameters));
                case "FAMILY", dd.family="UNSELECTED";
                case "PENDING"
                    i=find(cellfun(@(p)p.id=="WHEELBASE",cd.parameters)); original=cd.parameters{i}; q=original.parameter.definitionSI;
                    q=rmfield(q,{'id','quantity','scope','binding','unit'}); q.confirmation="PENDING_CONFIRMATION";
                    cd.parameters{i}=fsd.project.createConceptParameter('WHEELBASE',q,'m');
            end
            scenario=f.project.definition.scenarios{1}.definition;
            scenario.inputs.definition=fsd.construction.createParametricSeedDefinition(dd);
            project=fsd.project.createEngineeringProject(struct('concept',fsd.project.createVehicleConcept(cd), ...
                'scenarios',{{fsd.project.createEngineeringScenario(scenario)}}));
            r=fsd.project.designReadiness(project,'BUILD'); t.verifyEqual(r.status,"MISSING_DATA"); t.verifyNotEmpty(r.missing);
            t.verifyEmpty(project.definition.resources.geometries);
            file=string(tempname)+".mat"; t.addTeardown(@()delete(file));
            fsd.project.saveEngineeringProject(project,file); t.verifyEqual(fsd.project.loadEngineeringProject(file),project);
            t.verifyEqual(fsd.project.designReadiness(f.project,'BUILD').status,"READY");
        end
        function selectiveRevisionAndBoundResourceGuard(t,Revision)
            f=parametricSeedFixture('FRONT'); original=fsd.project.runEngineeringScenario(f.project,'BUILD','SEED');
            project=fsd.project.registerParametricSeed(f.project,original);
            bump=fsd.project.createEngineeringScenario(struct('id',"BUMP_FL",'engine',"BUMP", ...
                'scope',fsd.model.designScope('CORNER','FL'),'plan',struct('travel_m',[-.01;0;.01])));
            project=fsd.project.reviseEngineeringProject(project,struct('scenarios',{{project.definition.scenarios{1};bump}}));
            old=project; cd=project.definition.concept.definitionSI; dd=f.definition; build=project.definition.scenarios{1}.definition;
            switch Revision
                case {"WHEELBASE","TRACK","MASS"}
                    id="WHEELBASE"; value=1.7; unit='m';
                    if Revision=="TRACK", id="FRONT_TRACK"; value=1.32; end
                    if Revision=="MASS", id="VEHICLE_MASS"; value=210; unit='kg'; end
                    i=cellfun(@(p)p.id==id,cd.parameters);
                    cd.parameters{i}=fsd.project.createConceptParameter(id,struct('type',"ASSUMED",'value',value, ...
                        'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Explicit revised test input"),unit);
                case "DESCRIPTION", d=dd.definitionSI; d.description="Only presentation"; dd=fsd.construction.createParametricSeedDefinition(d);
                case "PARAM_DESCRIPTION"
                    d=dd.definitionSI; q=d.parameters{1}.definitionSI; input=rmfield(q,{'id','quantity','scope','binding','unit'});
                    input.description="Only presentation";
                    d.parameters{1}=fsd.construction.createSeedParameter(q.id,'FL',input,q.unit);
                    dd=fsd.construction.createParametricSeedDefinition(d);
                case "RADIUS", dd=replaceSeedDecision(dd,'WHEEL_EFFECTIVE_RADIUS',.26);
                case "UPRIGHT", dd=replaceSeedDecision(dd,'UPRIGHT_CLOCKING',.01);
                case "UBJ", dd=replaceSeedDecision(dd,'UBJ_X',.04);
                case "LBJ", dd=replaceSeedDecision(dd,'LBJ_Z',-.16);
                case "UCA", dd=replaceSeedDecision(dd,'UCA_HEIGHT',.355);
                case "LCA", dd=replaceSeedDecision(dd,'LCA_HEIGHT',.155);
                case "TIE", dd=replaceSeedDecision(dd,'TIE_OUT_X',.055);
                case "SYMMETRY"
                    [~,right]=parametricSeedInputs('FR'); d=dd.definitionSI; d.symmetry="NONE"; d.rightParameters=right.definitionSI.parameters;
                    dd=fsd.construction.createParametricSeedDefinition(d);
            end
            build.inputs.definition=dd; project=fsd.project.reviseEngineeringProject(project, ...
                struct('concept',fsd.project.createVehicleConcept(cd),'scenarios',{{fsd.project.createEngineeringScenario(build);bump}}));
            compatibility=fsd.project.resultCompatibility(original,project); ready=fsd.project.designReadiness(project,'BUMP_FL');
            if ismember(Revision,["DESCRIPTION","PARAM_DESCRIPTION","MASS"])
                t.verifyEqual(compatibility.status,"REUSABLE_DEPENDENCIES"); t.verifyEqual(ready.status,"READY");
            else
                t.verifyEqual(compatibility.status,"STALE"); t.verifyEqual(ready.status,"BLOCKED_BY_DEPENDENCY");
                t.verifyError(@()fsd.project.registerParametricSeed(project,original),'fsd:project:InvalidInput');
            end
            t.verifyEqual(project.definition.results{1},old.definition.results{1});
            t.verifyTrue(fsd.project.validateEngineeringProject(project));
        end
        function nativeBumpComparisonAndIndependentInvariants(t)
            f=parametricSeedFixture(); seed=fsd.construction.buildParametricSeed(f.definition,f.references); g=seed.geometries{1};
            check=fsd.project.checkParametricSeedBump(seed,struct('travel_m',[-.01;0;.01]));
            sweep=fsd.kinematics.solveBumpSweep(g,[-.01;0;.01],'m'); a=fsd.analysis.analyzeBumpSweep(g,sweep);
            t.verifyEqual(check.sources{1}.analysis.camber_rad,a.camber_rad,'AbsTol',1e-12);
            t.verifyEqual(check.sources{1}.analysis.toe_rad,a.toe_rad,'AbsTol',1e-12);
            t.verifyEqual(sweep.achievedWheelTravel_m,[-.01;0;.01],'AbsTol',1e-12);
            for j=1:3
                state=sweep.results(j).state; xyz=state.xyz_m;
                nominal=g.hardpoints.xyz_m([3,6,8,9,10],:);
                t.verifyEqual(norm(xyz(1,:)-xyz(2,:)),norm(nominal(1,:)-nominal(2,:)),'AbsTol',1e-12);
                in=g.hardpoints.xyz_m(1,:); t.verifyEqual(norm(xyz(1,:)-in),norm(nominal(1,:)-in),'AbsTol',1e-8);
                t.verifyEqual(sweep.results(j).uprightPose.rotationMatrix'*sweep.results(j).uprightPose.rotationMatrix,eye(3),'AbsTol',1e-12);
            end
            t.verifyTrue(fsd.project.validateParametricSeedBump(check,seed));
        end
        function validatorsPersistenceAndReadinessNeverSolve(t)
            f=parametricSeedFixture('FRONT'); d=f.project.definition.scenarios{1}.definition;
            d.engine="PARAMETRIC_BUMP"; d.plan=struct('travel_m',[-.01;0;.01]);
            project=fsd.project.reviseEngineeringProject(f.project,struct('scenarios',{{fsd.project.createEngineeringScenario(d)}}));
            result=fsd.project.runEngineeringScenario(project,'BUILD','SAMPLED');
            project=fsd.project.registerParametricSeed(project,result); file=string(tempname)+".mat"; t.addTeardown(@()delete(file));
            profile clear; profile on;
            fsd.project.validateEngineeringResult(result); fsd.project.validateEngineeringProject(project);
            fsd.project.validateParametricSeedBump(result.nativePayload.bumpCheck,result.nativePayload.seed);
            fsd.project.designReadiness(project,'BUILD'); fsd.project.saveEngineeringProject(project,file); loaded=fsd.project.loadEngineeringProject(file);
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["fsolve","fzero","solveBump","solveRack","solveActuation","boundedDirectSearch"])));
            t.verifyEqual(loaded,project);
        end
        function sourcePlanContextAndMatAttacks(t,Attack)
            f=parametricSeedFixture(); d=f.project.definition.scenarios{1}.definition; d.engine="PARAMETRIC_BUMP";
            d.plan=struct('travel_m',[-.01;0;.01]); project=fsd.project.reviseEngineeringProject(f.project, ...
                struct('scenarios',{{fsd.project.createEngineeringScenario(d)}}));
            result=fsd.project.runEngineeringScenario(project,'BUILD','ORIGINAL'); copy=result;
            switch Attack
                case "PLAN", copy.nativePayload.bumpCheck.plan.travel_m=[-.02;0;.02];
                case "OPTIONS", copy.nativePayload.bumpCheck.plan.solverOptions.MaxIterations=1;
                case "QUALITY", copy.nativePayload.bumpCheck.sources{1}.quality.rcond(1)=1;
                case "CONVERGENCE", copy.nativePayload.bumpCheck.sources{1}.sweep.converged(1)=false;
                case "SOURCE_GEOMETRY", copy.nativePayload.bumpCheck.sources{1}.geometry.hardpoints.xyz_m(1,3)=.4;
                case "SOURCE_GRID", copy.nativePayload.bumpCheck.sources{1}.sweep.requestedWheelTravel_m(1)=-.02;
                case "SEED_IDENTITY", copy.nativePayload.bumpCheck.seedIdentity.geometries{1}.wheelAxis=[0,1,0];
                case "CONTEXT", copy.prepared.context.references={};
                case "REVISION", copy.projectRevision=copy.projectRevision+1;
                case "NOMINAL", copy.nativePayload.seed.nominalStatus="INVALID";
                case "PROVENANCE", copy.nativePayload.seed.geometries{1}.hardpoints.sourceNote(:)="FORGED";
                case "BINDING", copy.scenarioAtExecution.definition.inputs.definition=replaceSeedDecision(f.definition,'UCA_HEIGHT',.36);
            end
            t.verifyError(@()fsd.project.validateEngineeringResult(copy),'fsd:project:InvalidEngineeringResult');
            file=string(tempname)+".mat"; t.addTeardown(@()delete(file));
            envelope=struct('kind',"FsdEngineeringProjectFile",'schemaVersion',"0.16.0",'project',project);
            envelope.project.definition.results={copy}; save(file,'envelope');
            t.verifyError(@()fsd.project.loadEngineeringProject(file),'fsd:project:InvalidEngineeringResult');
        end
        function noSteeringOrActuationInvented(t)
            f=parametricSeedFixture('FRONT'); result=fsd.project.runEngineeringScenario(f.project,'BUILD','SEED');
            p=fsd.project.registerParametricSeed(f.project,result);
            rack=fsd.project.createEngineeringScenario(struct('id',"RACK",'engine',"RACK", ...
                'scope',fsd.model.designScope('AXLE','FRONT'),'plan',struct('travel_m',0,'wheelTravel_m',[0,0])));
            act=fsd.project.createEngineeringScenario(struct('id',"ACT",'engine',"ACTUATION", ...
                'scope',fsd.model.designScope('CORNER','FL'),'plan',struct('travel_m',0)));
            p=fsd.project.reviseEngineeringProject(p,struct('scenarios',{{p.definition.scenarios{1};rack;act}}));
            t.verifyEqual(fsd.project.designReadiness(p,'RACK').status,"MISSING_DATA");
            t.verifyEqual(fsd.project.designReadiness(p,'ACT').status,"MISSING_DATA");
            steering=fsd.project.createSeedSteering(result.nativePayload.seed); p=fsd.project.registerParametricSeed(p,result,steering);
            t.verifyEqual(fsd.project.designReadiness(p,'RACK').status,"READY");
            r=fsd.project.runEngineeringScenario(p,'RACK','NATIVE_RACK'); t.verifyTrue(r.nativePayload.sweep.allConverged);
        end
        function incompatibleAssociatedResourcesRejectedNotRemoved(t)
            f=parametricSeedFixture('FRONT'); result=fsd.project.runEngineeringScenario(f.project,'BUILD','SEED');
            p=fsd.project.registerParametricSeed(f.project,result,fsd.project.createSeedSteering(result.nativePayload.seed));
            sd=p.definition.scenarios{1}.definition; sd.inputs.definition=replaceSeedDecision(f.definition,'UCA_HEIGHT',.355);
            p=fsd.project.reviseEngineeringProject(p,struct('scenarios',{{fsd.project.createEngineeringScenario(sd)}}));
            next=fsd.project.runEngineeringScenario(p,'BUILD','NEXT');
            t.verifyError(@()fsd.project.registerParametricSeed(p,next),'fsd:project:InvalidInput');
            t.verifyNotEmpty(p.definition.resources.steerings); t.verifyEqual(p.definition.results{1},result);
            p=fsd.project.registerParametricSeed(p,next,fsd.project.createSeedSteering(next.nativePayload.seed));
            t.verifyEqual(numel(p.definition.results),2);
        end
        function explicitSteeringMustUsePhysicalWheelbase(t)
            f=parametricSeedFixture('FRONT'); result=fsd.project.runEngineeringScenario(f.project,'BUILD','SEED');
            steering=fsd.model.createSteeringSystem(result.nativePayload.seed.axle,1.7,'m');
            t.verifyError(@()fsd.project.registerParametricSeed(f.project,result,steering),'fsd:project:InvalidInput');
        end
        function wheelbaseRevisionCannotReuseOldSteeringReference(t)
            f=parametricSeedFixture('FRONT'); result=fsd.project.runEngineeringScenario(f.project,'BUILD','SEED');
            p=fsd.project.registerParametricSeed(f.project,result,fsd.project.createSeedSteering(result.nativePayload.seed));
            cd=p.definition.concept.definitionSI; i=cellfun(@(q)q.id=="WHEELBASE",cd.parameters);
            cd.parameters{i}=fsd.project.createConceptParameter('WHEELBASE',struct('type',"ASSUMED",'value',1.7, ...
                'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Explicit new wheelbase"),'m');
            p=fsd.project.reviseEngineeringProject(p,struct('concept',fsd.project.createVehicleConcept(cd)));
            next=fsd.project.runEngineeringScenario(p,'BUILD','NEW_WB');
            t.verifyEqual(next.nativePayload.seed.geometries{1}.hardpoints.xyz_m,result.nativePayload.seed.geometries{1}.hardpoints.xyz_m);
            t.verifyError(@()fsd.project.registerParametricSeed(p,next),'fsd:project:InvalidInput');
            p=fsd.project.registerParametricSeed(p,next,fsd.project.createSeedSteering(next.nativePayload.seed));
            t.verifyEqual(p.definition.resources.steerings{1}.rearAxleX_m,1.7);
        end
        function geometryRequiresNeitherMassCgNorGravity(t)
            f=parametricSeedFixture(); d=f.concept.definitionSI;
            d.parameters=d.parameters(cellfun(@(p)ismember(p.id,["WHEELBASE","FRONT_TRACK"]),d.parameters));
            p=fsd.project.reviseEngineeringProject(f.project,struct('concept',fsd.project.createVehicleConcept(d)));
            t.verifyEqual(fsd.project.designReadiness(p,'BUILD').status,"READY");
            r=fsd.project.runEngineeringScenario(p,'BUILD','PURE_GEOMETRY');
            t.verifyEqual(r.nativePayload.seed.nominalStatus,"VALID");
            t.verifyEmpty(r.prepared.vehicle); t.verifyEmpty(r.prepared.loadCase);
        end
        function inputReadyDoesNotMeanNominalOrSampledValid(t)
            f=parametricSeedFixture(); sd=f.project.definition.scenarios{1}.definition;
            sd.inputs.definition=replaceSeedDecision(f.definition,'UCA_LATERAL',.7);
            sd.engine="PARAMETRIC_BUMP"; sd.plan=struct('travel_m',[-.01;0;.01]);
            p=fsd.project.reviseEngineeringProject(f.project,struct('scenarios',{{fsd.project.createEngineeringScenario(sd)}}));
            t.verifyEqual(fsd.project.designReadiness(p,'BUILD').status,"READY");
            profile clear; profile on; r=fsd.project.runEngineeringScenario(p,'BUILD','INVALID_NOMINAL');
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyEqual(r.nativePayload.seed.nominalStatus,"INVALID"); t.verifyEmpty(r.nativePayload.bumpCheck);
            t.verifyFalse(any(contains(names,["fsolve","solveBump"])));
        end
        function completeExampleUsesGeneratedNativeSeed(t)
            output=conceptToSeedExample(false); result=output.search.nativePayload;
            t.verifyEqual(result.problem.seed,output.seed.geometries{1});
            t.verifyTrue(fsd.synthesis.validateSynthesisResult(result));
            t.verifyGreaterThan(result.search.evaluationCount,1);
            t.verifyLessThan(result.search.records{result.selectedIndex}.score,result.search.records{1}.score);
            t.verifyEqual(output.loaded,output.project);
        end
    end
end
