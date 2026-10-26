classdef TestAntiRollBarProject < matlab.unittest.TestCase
    properties
        Project
        Bar
        Result
    end
    methods(TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
            p=fsd.project.createEngineeringProject(struct('concept',fsd.project.createVehicleConcept(struct('id',"ARB_PROJECT"))));
            [p,b]=fsd.project.registerAntiRollBar(p,antiRollBarInputs);
            p=fsdui.upsertScenario(p,scenario(b,"ARB_MECHANICAL"));
            [r,p]=fsd.project.runEngineeringScenario(p,'ARB_STUDY','ARB_ORIGINAL');
            t.Project=p; t.Bar=b; t.Result=r;
        end
    end
    methods(Test)
        function equivalentExecutionAndExactMat(t)
            r=t.Result; t.verifyTrue(all(cellfun(@(a)a.available,r.nativePayload.study.responses)));
            t.verifyEqual(r.nativePayload.study.responses{1}.energy_J,2,'AbsTol',1e-14);
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); file=fullfile(folder.Folder,'arb.mat');
            fsd.project.saveEngineeringProject(t.Project,file,false); t.verifyEqual(fsd.project.loadEngineeringProject(file),t.Project);
        end
        function partialResourcesAndPlansAreStorable(t)
            [p,b]=fsd.project.registerAntiRollBar(t.Project,struct('id',"PENDING_ARB",'axleId',"REAR"));
            d=struct('id',"PENDING_STUDY",'engine',"ARB_MECHANICAL",'scope',fsd.model.designScope('AXLE','REAR'), ...
                'inputs',struct('arbId',b.definition.id,'arbRevision',1));
            p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
            r=fsd.project.designReadiness(p,d.id); t.verifyEqual(r.status,"MISSING_DATA");
            t.verifyTrue(any(r.missing=="PLAN:wheelTravel_m"));
            t.verifyEmpty(b.definition.parameters.freeDeflection_m);
        end
        function immutableRevisionsAndSelectiveMaterialDependencies(t)
            d=t.Bar.definition; d.parameters.G_Pa=7e10;
            d.provenance.G_Pa=struct('sourceKind',"ASSUMED",'sourceNote',"Unconsumed material declaration");
            [p,b]=fsd.project.registerAntiRollBar(t.Project,d); p=retarget(p,b);
            t.verifyEqual(fsd.project.resultCompatibility(t.Result,p).status,"REUSABLE_DEPENDENCIES");
            t.verifyEqual(p.definition.results,t.Project.definition.results);
            d=b.definition; d.parameters.linearStiffness_N_per_m=12000;
            [changed,b]=fsd.project.registerAntiRollBar(p,d); changed=retarget(changed,b);
            t.verifyEqual(fsd.project.resultCompatibility(t.Result,changed).status,"STALE");
            resources=p.definition.resources; resources.antiRollBars=resources.antiRollBars(2:end);
            t.verifyError(@()fsd.project.reviseEngineeringProject(p,struct('resources',resources)),'fsd:project:InvalidInput');
        end
        function independentResourcesDoNotInvalidateEvidence(t)
            d=antiRollBarInputs('EQUIVALENT_LINEAR','REAR'); d.id="REAR_ARB";
            [p,~]=fsd.project.registerAntiRollBar(t.Project,d);
            t.verifyEqual(fsd.project.resultCompatibility(t.Result,p).status,"REUSABLE_DEPENDENCIES");
            td=tireCharacterizationInputs; [p,~]=fsd.project.registerTire(p,td);
            t.verifyEqual(fsd.project.resultCompatibility(t.Result,p).status,"REUSABLE_DEPENDENCIES");
        end
        function frontBarCannotInvalidateIndependentRearBump(t)
            [p,~]=globalStaticGuidedInputs; [p,b]=fsd.project.registerAntiRollBar(p,antiRollBarInputs);
            rear=fsd.project.createEngineeringScenario(struct('id',"INDEPENDENT_REAR",'engine',"BUMP", ...
                'scope',fsd.model.designScope('CORNER','RL'),'plan',struct('travel_m',[-.001;0;.001])));
            p=fsdui.upsertScenario(p,rear); [r,p]=fsd.project.runEngineeringScenario(p,rear.definition.id,'REAR_BEFORE_BAR_CHANGE');
            d=b.definition; d.parameters.linearStiffness_N_per_m=12000; [p,~]=fsd.project.registerAntiRollBar(p,d);
            t.verifyEqual(fsd.project.resultCompatibility(r,p).status,"REUSABLE_DEPENDENCIES");
        end
        function geometricConsumptionAndSamplingAreSelective(t)
            [p,~]=globalStaticGuidedInputs; d=geometricAntiRollBarInputs(p,'FRONT','UPRIGHT');
            [p,b]=fsd.project.registerAntiRollBar(p,d); sd=scenario(b,'ARB_MECHANICAL').definition;
            sd.plan.driverTravel_m={(-.02:.004:.02)',(-.02:.004:.02)'};
            p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(sd)); [r,p]=fsd.project.runEngineeringScenario(p,sd.id,'CONSUMPTION_BASE');
            base=p;
            for mode=["MATERIAL_UNUSED","GEOMETRY","REFERENCE","ADJUSTMENT","GRID","OPTIONS"]
                current=base; declaration=b.definition; request=sd; expected="STALE";
                switch mode
                    case "MATERIAL_UNUSED"
                        declaration.parameters.G_Pa=8e10; declaration.provenance.G_Pa=struct('sourceKind',"ASSUMED",'sourceNote',"Stored, unconsumed under known port law"); expected="REUSABLE_DEPENDENCIES";
                    case "GEOMETRY"
                        declaration.parameters.armPoints_m(:,1)=declaration.parameters.armPoints_m(:,1)+.001;
                        declaration.parameters.driverPoints_m(:,1)=declaration.parameters.driverPoints_m(:,1)+.001;
                    case "REFERENCE"
                        declaration.referenceMode="DECLARED_FREE"; declaration.parameters.freeAngle_rad=0;
                        declaration.provenance.freeAngle_rad=struct('sourceKind',"KNOWN",'sourceNote',"Explicit changed unloaded angle");
                    case "ADJUSTMENT", declaration.adjustmentId="OTHER_ATTACHMENT_HOLE";
                    case "GRID", request.plan.wheelTravel_m=flipud(request.plan.wheelTravel_m);
                    case "OPTIONS", request.options=struct('MaxContinuationStep_m',.004);
                end
                if ~ismember(mode,["GRID","OPTIONS"])
                    [current,changed]=fsd.project.registerAntiRollBar(current,declaration); request.inputs.arbRevision=changed.definition.revision;
                end
                current=fsdui.upsertScenario(current,fsd.project.createEngineeringScenario(request));
                t.verifyEqual(fsd.project.resultCompatibility(r,current).status,expected,mode);
                t.verifyEqual(current.definition.results,base.definition.results);
            end
            d=b.definition; d.stiffnessMode="CIRCULAR_SHAFT"; d.section="SOLID"; d.parameters.kTheta_Nm_per_rad=[];
            d.parameters.G_Pa=8e10; d.parameters.outerDiameter_m=.01; d.parameters.effectiveLength_m=.5;
            for key=["G_Pa","outerDiameter_m","effectiveLength_m"], d.provenance.(key)=struct('sourceKind',"ASSUMED",'sourceNote',"Explicit calculated shaft"); end
            [p,b]=fsd.project.registerAntiRollBar(base,d); sd.inputs.arbRevision=b.definition.revision;
            p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(sd)); [calculated,p]=fsd.project.runEngineeringScenario(p,sd.id,'CALCULATED_SECTION');
            d=b.definition; d.parameters.G_Pa=7e10; [p,b]=fsd.project.registerAntiRollBar(p,d); sd.inputs.arbRevision=b.definition.revision;
            p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(sd)); t.verifyEqual(fsd.project.resultCompatibility(calculated,p).status,"STALE");
        end
        function canonicalTamperIsRejected(t)
            forged=t.Result; forged.nativePayload.study.responses{1}.energy_J=0;
            t.verifyError(@()fsd.project.validateEngineeringResult(forged),'fsd:project:InvalidEngineeringResult');
        end
        function nativeRockerSourcesGeometryAndStiffnessOnlyRevision(t)
            [p,~]=globalStaticGuidedInputs; d=geometricAntiRollBarInputs(p,'FRONT','ROCKER');
            [p,b]=fsd.project.registerAntiRollBar(p,d); sd=scenario(b,'ARB_KINEMATICS');
            sd.definition.plan.driverTravel_m={(-.02:.004:.02)',(-.02:.004:.02)'};
            sd=fsd.project.createEngineeringScenario(sd.definition); p=fsdui.upsertScenario(p,sd);
            [r,p]=fsd.project.runEngineeringScenario(p,sd.definition.id,'KINEMATICS_ORIGINAL');
            t.verifyTrue(all(cellfun(@(x)x.available,r.nativePayload.study.responses)));
            d=b.definition; d.parameters.kTheta_Nm_per_rad=120; [p,b]=fsd.project.registerAntiRollBar(p,d); p=retarget(p,b);
            t.verifyEqual(fsd.project.resultCompatibility(r,p).status,"REUSABLE_DEPENDENCIES");
            sd=p.definition.scenarios{1}.definition; sd.engine="ARB_MECHANICAL"; p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(sd));
            [m,~]=fsd.project.runEngineeringScenario(p,sd.id,'GEOMETRIC_MECHANICAL');
            t.verifyTrue(all(cellfun(@(x)x.available,m.nativePayload.study.responses)));
        end
        function globalAssignmentsConsumeOnlyActiveAxes(t)
            [p,gd]=globalStaticGuidedInputs; [p,b]=fsd.project.registerAntiRollBar(p,antiRollBarInputs);
            p=fsd.project.assignAntiRollBars(p,{struct('axleId',"FRONT",'arbId',b.definition.id,'arbRevision',1)});
            gd.inputs.arbAxles="FRONT"; p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(gd));
            t.verifyEqual(fsd.project.designReadiness(p,gd.id).status,"READY");
            [r,p]=fsd.project.runEngineeringScenario(p,gd.id,'GLOBAL_ARB');
            t.verifyEqual(numel(r.nativePayload.equilibrium.alternatives{1}.state.antiRollBars),1);
            d=b.definition; d.parameters.linearStiffness_N_per_m=11000; [p,b]=fsd.project.registerAntiRollBar(p,d);
            p=fsd.project.assignAntiRollBars(p,{struct('axleId',"FRONT",'arbId',b.definition.id,'arbRevision',2)});
            t.verifyEqual(fsd.project.resultCompatibility(r,p).status,"STALE");
        end
        function sizingNeedsOnlySectionDataAndPreservesTarget(t)
            d=struct('id',"SIZING_BAR",'axleId',"FRONT",'representation',"COAXIAL_TORSION",'section',"SOLID", ...
                'parameters',struct('G_Pa',8e10,'effectiveLength_m',.5),'provenance',struct());
            for key=["G_Pa","effectiveLength_m"], d.provenance.(key)=struct('sourceKind',"ASSUMED",'sourceNote',"Explicit sizing benchmark"); end
            [p,b]=fsd.project.registerAntiRollBar(t.Project,d);
            target=struct('stiffness_Nm_per_rad',100,'sourceKind',"KNOWN",'sourceNote',"User-selected target, not optimized");
            sd=struct('id',"SECTION_SIZING",'engine',"ARB_SIZING",'scope',fsd.model.designScope('AXLE','FRONT'), ...
                'inputs',struct('arbId',b.definition.id,'arbRevision',1),'plan',struct('target',target));
            p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(sd));
            t.verifyEqual(fsd.project.designReadiness(p,sd.id).status,"READY");
            [r,~]=fsd.project.runEngineeringScenario(p,sd.id,'SIZED_SECTION');
            t.verifyEqual(r.nativePayload.sizing.outerDiameter_m,(32*.5*100/(pi*8e10))^.25,'RelTol',1e-14);
            t.verifyEqual(r.nativePayload.target,target);
        end
        function rollUsesExistingNativeMotionAndGeometricGlobalIsCoupled(t)
            [p,gd]=globalStaticGuidedInputs; d=geometricAntiRollBarInputs(p,'FRONT','ROCKER');
            [p,b]=fsd.project.registerAntiRollBar(p,d); sd=scenario(b,'ARB_MECHANICAL').definition;
            sd.plan=struct('motion',"ROLL",'rollAngles_rad',[-.005;0;.005],'axleHeave_m',0, ...
                'driverTravel_m',{{(-.02:.004:.02)',(-.02:.004:.02)'}});
            p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(sd));
            [r,p]=fsd.project.runEngineeringScenario(p,sd.id,'ARB_NATIVE_ROLL');
            t.verifyEqual(r.nativePayload.motion.requestedBodyRollAngle_rad,sd.plan.rollAngles_rad);
            t.verifyTrue(all(cellfun(@(x)x.available,r.nativePayload.study.responses)));
            p=fsd.project.assignAntiRollBars(p,{struct('axleId',"FRONT",'arbId',b.definition.id,'arbRevision',1)});
            gd.inputs.arbAxles="FRONT"; p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(gd));
            [g,~]=fsd.project.runEngineeringScenario(p,gd.id,'GEOMETRIC_GLOBAL');
            t.assertEqual(g.nativePayload.equilibrium.selectedIndex,1);
            state=g.nativePayload.equilibrium.alternatives{1}.state;
            t.verifyTrue(state.antiRollBars{1}.available); t.verifyLessThan(norm(state.worldMomentResidual_Nm),1e-6);
        end
    end
end
function s=scenario(bar,engine)
s=fsd.project.createEngineeringScenario(struct('id',"ARB_STUDY",'engine',string(engine), ...
    'scope',fsd.model.designScope('AXLE',bar.definition.axleId),'inputs',struct('arbId',bar.definition.id,'arbRevision',bar.definition.revision), ...
    'plan',struct('wheelTravel_m',[.01,-.01;0,0;-.01,.01])));
end
function p=retarget(p,b)
sd=p.definition.scenarios{1}.definition; sd.inputs.arbRevision=b.definition.revision;
p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(sd));
end
