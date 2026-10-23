classdef TestGuidedGlobalStatic < matlab.unittest.TestCase
    % Production-path integration. Numerical oracles documented in contract.
    properties
        Project
        Definition
        Result
    end
    methods(TestClassSetup)
        function fixture(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
            [p,d]=globalStaticGuidedInputs(); c=fsdui.Controller(p); cleanup=onCleanup(@()c.close());
            c.run('GLOBAL_CONFIG',struct('definition',d),false);
            t.assertEqual(c.LastValue.status,"READY");
            c.run('GLOBAL_RUN',struct('scenarioId',d.id,'resultId',"GLOBAL_TEST"),false);
            t.Project=c.Project; t.Definition=d; t.Result=c.LastValue;
        end
    end
    methods(Test)
        function productionIndependentNominalBalance(t)
            r=t.Result.nativePayload.equilibrium; t.assertEqual(r.selectedIndex,1);
            s=r.alternatives{1}.state;
            % Analytic nominal rocker closure sets FsMR=500 per corner. The pp
            % derivative approximation is checked against the original budget.
            t.verifyEqual(s.normalForces_N,500*ones(4,1),'AbsTol',.05);
            t.verifyEqual(s.q,[-.005;zeros(6,1)],'AbsTol',1e-5);
            t.verifyLessThan(abs(s.worldForceResidual_N),1e-5);
            t.verifyLessThan(norm(s.worldMomentResidual_Nm),2e-6);
            t.verifyTrue(r.alternatives{1}.converged);
            t.verifyEqual(s.approximation,"SAMPLED_PATH_APPROXIMATION");
            for k=1:4, t.verifyEqual(s.corners{k}.damperAxialResistance_N,0); end
        end
        function missingVehicleDataIsSpecific(t)
            p=t.Project; d=p.definition.concept.definitionSI;
            d.parameters=d.parameters(~cellfun(@(x)x.id=="CG_Z",d.parameters));
            p=fsd.project.reviseEngineeringProject(p,struct('concept',fsd.project.createVehicleConcept(d)));
            r=fsd.project.designReadiness(p,t.Definition.id);
            t.verifyEqual(r.status,"MISSING_DATA"); t.verifyTrue(any(r.missing=="CONCEPT:CG_Z"));
        end
        function missingCornerAndCoiloverAreSpecific(t)
            p=t.Project; rs=p.definition.resources;
            for name=["geometries","actuations","mechanicals"]
                rs.(name)=rs.(name)(~cellfun(@(x)x.cornerId=="RR",rs.(name)));
            end
            p=fsd.project.reviseEngineeringProject(p,struct('resources',rs));
            r=fsd.project.designReadiness(p,t.Definition.id);
            t.verifyTrue(all(ismember(["GEOMETRY:RR";"ACTUATION:RR";"MECHANICAL:RR"],r.missing)));
        end
        function nonzeroVelocityBlocked(t)
            d=t.Definition; d.plan.cornerPlans.RL.wheelVelocity_m_per_s=1;
            p=fsdui.upsertScenario(t.Project,fsd.project.createEngineeringScenario(d));
            r=fsd.project.designReadiness(p,d.id); t.verifyEqual(r.status,"INVALID_INPUT");
        end
        function tireOrderBlocked(t)
            d=t.Definition; d.inputs.tires=flipud(d.inputs.tires);
            p=fsdui.upsertScenario(t.Project,fsd.project.createEngineeringScenario(d));
            r=fsd.project.designReadiness(p,d.id); t.verifyEqual(r.status,"INVALID_INPUT");
        end
        function controlsAndTireChangesStaleWithoutDeletingHistory(t)
            for field=["TIRE","ROAD","SEED","OPTIONS","PATH"]
                d=t.Definition;
                switch field
                    case "TIRE"
                        tire=d.inputs.tires{3}; tire.stiffness_N_per_m=tire.stiffness_N_per_m*1.1;
                        tire.identity.stiffness_N_per_m=tire.stiffness_N_per_m; d.inputs.tires{3}=tire;
                    case "ROAD", d.plan.systemOptions.roadHeight_m=.001;
                    case "SEED", d.plan.initialGuesses(1)=-.006;
                    case "OPTIONS", d.options.forceTolerance_N=1e-4;
                    case "PATH", d.plan.cornerPlans.RR.travel_m=(-.02:.001:.02)';
                end
                p=fsdui.upsertScenario(t.Project,fsd.project.createEngineeringScenario(d));
                r=fsd.project.resultCompatibility(t.Result,p); t.verifyEqual(r.status,"STALE",field);
                t.verifyEqual(p.definition.results,t.Project.definition.results);
            end
        end
        function massAndCgChangesStale(t)
            for id=["VEHICLE_MASS","CG_X","CG_Y","CG_Z","UNSPRUNG_MASS_FL"]
                p=t.Project; d=p.definition.concept.definitionSI; ps=d.parameters;
                i=find(cellfun(@(x)x.id==id,ps)); v=ps{i}.parameter.definitionSI.value;
                unit="m"; if contains(id,'MASS'), unit="kg"; end
                ps{i}=fsd.project.createConceptParameter(id,struct('value',v+.01,'availability',"ASSUMED", ...
                    'sourceKind',"ASSUMED",'sourceNote',"Explicit sensitivity test"),unit);
                d.parameters=ps; p=fsd.project.reviseEngineeringProject(p,struct('concept',fsd.project.createVehicleConcept(d)));
                r=fsd.project.resultCompatibility(t.Result,p); t.verifyEqual(r.status,"STALE",id);
            end
        end
        function unrelatedConceptChangeReusable(t)
            p=t.Project; d=p.definition.concept.definitionSI;
            d.parameters{end+1}=fsd.project.createConceptParameter('WHEEL_WIDTH_FRONT', ...
                struct('value',.17,'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Unconsumed value"),'m');
            p=fsd.project.reviseEngineeringProject(p,struct('concept',fsd.project.createVehicleConcept(d)));
            r=fsd.project.resultCompatibility(t.Result,p); t.verifyEqual(r.status,"REUSABLE_DEPENDENCIES");
            resources=p.definition.resources;
            resources.packaging={packagingInputs(resources.geometries{1},p.definition.revision)};
            p=fsd.project.reviseEngineeringProject(p,struct('resources',resources));
            r=fsd.project.resultCompatibility(t.Result,p); t.verifyEqual(r.status,"REUSABLE_DEPENDENCIES");
            t.verifyEqual(p.definition.results,t.Project.definition.results);
        end
        function alteredBumpControlsRejected(t)
            r=t.Result; r.nativePayload.system.sources{2}.bump.requestedWheelTravel_m(1)=-.03;
            t.verifyError(@()fsd.project.validateEngineeringResult(r),'fsd:project:InvalidEngineeringResult');
        end
        function alteredGlobalForcesRejected(t)
            r=t.Result; r.nativePayload.equilibrium.alternatives{1}.state.normalForces_N(1)=123;
            t.verifyError(@()fsd.project.validateEngineeringResult(r),'fsd:project:InvalidEngineeringResult');
        end
        function ownerBindsCompleteVehicleNotJustResultId(t)
            q=request(t.Project,t.Definition.id); alt=q;
            d=t.Definition; d.plan.initialGuesses(1)=-.006;
            alt.project=fsdui.upsertScenario(q.project,fsd.project.createEngineeringScenario(d));
            r=fsdui.perform(alt);
            t.verifyTrue(fsd.project.validateEngineeringProject(r.project));
            t.verifyError(@()fsdui.validateOperationResponse(q,r),'fsd:ui:SemanticMismatch');
        end
        function receiptAndEvidenceRunNoForwardSolves(t)
            q=request(t.Project,t.Definition.id); r=fsdui.perform(q);
            profile clear; profile on; cleanup=onCleanup(@()profile('off'));
            fsdui.validateOperationResponse(q,r); e=fsdui.globalStaticEvidence(r.value,1);
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["solveBump","solveActuation","solveGlobalStatic","fsolve"])));
            t.verifyEqual(cell2mat(e.corners(:,11)),r.value.nativePayload.equilibrium.alternatives{1}.state.normalForces_N);
        end
        function tableBoundaryRoundTrip(t)
            s=fsd.project.createEngineeringScenario(t.Definition); rows=fsdui.globalStaticConfiguration('ROWS',s);
            d=fsdui.globalStaticConfiguration('DEFINITION',rows,s); recovered=fsd.project.createEngineeringScenario(d);
            t.verifyEqual(recovered.definition.plan.cornerPlans,s.definition.plan.cornerPlans);
            t.verifyEqual(recovered.definition.inputs,s.definition.inputs);
            t.verifyEqual(recovered.definition.plan.initialGuesses,s.definition.plan.initialGuesses,'AbsTol',1e-17);
            rows.tires{1,2}='';
            t.verifyError(@()fsdui.globalStaticConfiguration('DEFINITION',rows,s),'fsd:ui:GlobalInput');
        end
        function matFullHistoryExact(t)
            file=string(tempname)+".mat"; cleanup=onCleanup(@()delete(file));
            fsd.project.saveEngineeringProject(t.Project,file,false);
            p=fsd.project.loadEngineeringProject(file); t.verifyEqual(p,t.Project);
        end
        function fourIndependentMechanicalResourcesAffectPose(t)
            p=t.Project; rs=p.definition.resources;
            for k=1:4
                m=rs.mechanicals{k}; m.spring.preloadCompression_m=m.spring.preloadCompression_m*(1+.04*k);
                m.derivedStaticGeometry=struct();
                % Rebuild via public model factory, preserving the historical law.
                [~,~,~,~,d,units]=actuationSynthesisSeed('PUSHROD',m.cornerId);
                d.spring.preloadCompression=m.spring.preloadCompression_m;
                d.metadata.sourceNote="Four independently changed synthetic preloads; no measured hardware data";
                rs.mechanicals{k}=fsd.model.createSpringDamperModel(rs.actuations{k},d,units);
            end
            p=fsd.project.reviseEngineeringProject(p,struct('resources',rs));
            % The original narrow numerical box excludes the changed setup.
            r=fsd.project.runEngineeringScenario(p,t.Definition.id,'ASYMMETRIC_GLOBAL');
            t.verifyTrue(isnan(r.nativePayload.equilibrium.selectedIndex));
            t.verifyEqual(r.nativePayload.equilibrium.attempts{1}.solution.status,"ARTIFICIAL_SEARCH_BOUNDARY");
            d=extendedDomain(t.Definition); p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
            r=fsd.project.runEngineeringScenario(p,d.id,'ASYMMETRIC_EXTENDED');
            e=r.nativePayload.equilibrium; t.assertTrue(isfinite(e.selectedIndex)); s=e.alternatives{e.selectedIndex}.state;
            t.verifyGreaterThan(norm(s.q-t.Result.nativePayload.equilibrium.alternatives{1}.state.q),1e-5);
            t.verifyEqual(sum(s.normalForces_N),2000,'AbsTol',1e-5);
            t.verifyLessThan(norm(s.worldMomentResidual_Nm),2e-6);
            t.verifyEqual(fsd.project.resultCompatibility(t.Result,p).status,"STALE");
        end
        function missingTireAndInvalidTravelReadiness(t)
            d=t.Definition; d.inputs.tires{2}=[];
            p=fsdui.upsertScenario(t.Project,fsd.project.createEngineeringScenario(d));
            r=fsd.project.designReadiness(p,d.id); t.verifyTrue(any(r.missing=="TIRE:FR:CONFIGURE_VERTICAL_TIRE"));
            d=t.Definition; d.plan.cornerPlans.FL.travel_m=[0;.01];
            p=fsdui.upsertScenario(t.Project,fsd.project.createEngineeringScenario(d));
            r=fsd.project.designReadiness(p,d.id); t.verifyEqual(r.status,"INVALID_INPUT");
        end
        function changedGeometryAndActuationUseFullContent(t)
            for change=["GEOMETRY","ACTUATION"]
                p=t.Project; rs=p.definition.resources;
                % Registry order is canonical FL/FR/RL/RR; corner FL modified.
                g=rs.geometries{1}; [~,~,~,ad,md,units]=actuationSynthesisSeed('PUSHROD','FL');
                md.spring.preloadCompression=rs.mechanicals{1}.spring.preloadCompression_m;
                if change=="GEOMETRY"
                    xyz=g.hardpoints.xyz_m; xyz(1,3)=xyz(1,3)+.001;
                    g=fsd.model.createDoubleWishboneGeometry('FL',g.hardpoints.ids,xyz,'m',g.wheel.wheelAxis);
                else, ad.damper.chassisPoint(2)=ad.damper.chassisPoint(2)+.001;
                end
                a=fsd.model.createActuationGeometry(g,ad,'m'); m=fsd.model.createSpringDamperModel(a,md,units);
                rs.geometries{1}=g; rs.actuations{1}=a; rs.mechanicals{1}=m;
                p=fsd.project.reviseEngineeringProject(p,struct('resources',rs));
                t.verifyEqual(fsd.project.resultCompatibility(t.Result,p).status,"STALE",change);
                t.verifyEqual(p.definition.results,t.Project.definition.results);
            end
        end
        function cgOffsetReactionsAndReflection(t)
            states=cell(2,1);
            for side=1:2
                p=t.Project; d=p.definition.concept.definitionSI; ps=d.parameters;
                for id=["CG_X","CG_Y"]
                    value=.78; if id=="CG_Y", value=.005*(3-2*side); end
                    i=cellfun(@(x)x.id==id,ps);
                    ps{i}=fsd.project.createConceptParameter(id,struct('value',value,'availability',"ASSUMED", ...
                        'sourceKind',"ASSUMED",'sourceNote',"Independent reflection/lever balance case"),'m');
                end
                d.parameters=ps; p=fsd.project.reviseEngineeringProject(p,struct('concept',fsd.project.createVehicleConcept(d)));
                domain=extendedDomain(t.Definition); p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(domain));
                r=fsd.project.runEngineeringScenario(p,t.Definition.id,'OFFSET'); e=r.nativePayload.equilibrium;
                t.assertTrue(isfinite(e.selectedIndex)); s=e.alternatives{e.selectedIndex}.state; states{side}=s;
                wc=cell2mat(cellfun(@(c)c.wheelCenterWorld_m,s.corners,'UniformOutput',false));
                % Independent world lever balances, mu=0. No use of core residual.
                f=s.normalForces_N;
                t.verifyEqual(sum(f),2000,'AbsTol',1e-5);
                t.verifyEqual(wc(:,1)'*f,2000*s.totalCgWorld_m(1),'AbsTol',2e-6);
                t.verifyEqual(wc(:,2)'*f,2000*s.totalCgWorld_m(2),'AbsTol',2e-6);
                t.verifyGreaterThan(s.axleLoads_N(1),1000);
            end
            t.verifyEqual(states{1}.normalForces_N,states{2}.normalForces_N([2,1,4,3]),'AbsTol',1e-4);
            t.verifyEqual(states{1}.roll_rad,-states{2}.roll_rad,'AbsTol',1e-8);
        end
        function noSolutionPreservesAttemptAndDoesNotPublishNominal(t)
            d=t.Definition; d.options.bounds(1,:)=[.01,.03]; d.plan.initialGuesses(1)=.02;
            p=fsdui.upsertScenario(t.Project,fsd.project.createEngineeringScenario(d));
            r=fsd.project.runEngineeringScenario(p,d.id,'NO_ROOT'); e=r.nativePayload.equilibrium;
            t.verifyTrue(isnan(e.selectedIndex)); t.verifyEmpty(e.alternatives); t.verifyNotEmpty(e.attempts);
            t.verifyFalse(e.attempts{1}.solution.converged);
            display=fsdui.globalStaticEvidence(r,NaN); t.verifyEmpty(display.pose); t.verifyEmpty(display.corners);
            t.verifyTrue(fsd.project.validateEngineeringResult(r));
        end
        function asymmetricFourIndependentFootprintsAndTires(t)
            [p,d]=globalStaticGuidedInputs(); rs=p.definition.resources; ids=["FL","FR","RL","RR"];
            shifts=[0,-.003,0;.01,.007,0;-.02,-.011,0;.015,-.005,0];
            rates=[28000,29000,31000,32000]; kt=[90000,100000,110000,120000]; wc=zeros(4,3);
            for k=1:4
                id=ids(k); [g,~,~,ad,md,units]=actuationSynthesisSeed('PUSHROD',id); delta=shifts(k,:);
                g=fsd.model.createDoubleWishboneGeometry(id,g.hardpoints.ids,g.hardpoints.xyz_m+delta,'m',g.wheel.wheelAxis);
                ad.suspensionAttachment.point=ad.suspensionAttachment.point+delta;
                ad.rocker.axis.point=ad.rocker.axis.point+delta;
                ad.rocker.actuationRodPoint=ad.rocker.actuationRodPoint+delta;
                ad.rocker.damperPoint=ad.rocker.damperPoint+delta; ad.damper.chassisPoint=ad.damper.chassisPoint+delta;
                a=fsd.model.createActuationGeometry(g,ad,'m');
                md.spring.rate=rates(k); md.spring.preloadCompression=rs.mechanicals{k}.spring.preloadCompression_m*30000/rates(k);
                md.metadata.sourceNote="Four distinct synthetic rates/preloads, explicitly defined by the independent benchmark";
                rs.geometries{k}=g; rs.actuations{k}=a; rs.mechanicals{k}=fsd.model.createSpringDamperModel(a,md,units);
                wc(k,:)=fsd.model.getPoint(g,id+"_WHEEL_CENTER");
                % Independent compression law: N=kt*(R0-WCworldZ), desired h=-.005.
                d.inputs.tires{k}=fsd.model.createVerticalTireModel(struct('cornerId',id,'modelType',"LINEAR_VERTICAL_UNILATERAL", ...
                    'stiffness',kt(k),'unloadedRadius',wc(k,3)-.005+500/kt(k), ...
                    'sourceKind',"ASSUMED",'sourceNote',"Four distinct synthetic tire/load closure cases"), ...
                    struct('length',"m",'stiffness',"N/m"));
            end
            cd=p.definition.concept.definitionSI; center=mean(wc,1);
            for j=1:2
                id="CG_"+extractBetween("XY",j,j); match=cellfun(@(x)x.id==id,cd.parameters);
                cd.parameters{match}=fsd.project.createConceptParameter(id,struct('value',center(j),'availability',"ASSUMED", ...
                    'sourceKind',"ASSUMED",'sourceNote',"Independent mean support position gives zero nominal moments"),'m');
            end
            p=fsd.project.reviseEngineeringProject(p,struct('resources',rs,'concept',fsd.project.createVehicleConcept(cd)));
            p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
            r=fsd.project.runEngineeringScenario(p,d.id,'FOUR_DISTINCT'); e=r.nativePayload.equilibrium;
            t.assertTrue(isfinite(e.selectedIndex)); s=e.alternatives{e.selectedIndex}.state;
            t.verifyEqual(s.q,[-.005;zeros(6,1)],'AbsTol',1e-5);
            t.verifyEqual(s.normalForces_N,500*ones(4,1),'AbsTol',.05);
            t.verifyLessThan(norm(s.worldMomentResidual_Nm),2e-6);
            for k=1:4, t.verifyEqual(r.nativePayload.system.sources{k}.geometry,rs.geometries{k}); end
        end
    end
end
function q=request(p,id)
q=fsdui.workerRequest(struct('operationId',1,'epoch',0,'action',"GLOBAL_RUN",'project',p, ...
    'arguments',struct('scenarioId',id,'resultId',"OWNER_GLOBAL")));
end
function d=extendedDomain(d)
% Explicit case-specific coverage increase; not a new default or tolerance.
for id=["FL","FR","RL","RR"], d.plan.cornerPlans.(id).travel_m=(-.05:.002:.05)'; end
d.options.bounds=[-.1,.1;-.15,.15;-.15,.15;repmat([-.045,.045],4,1)];
end
