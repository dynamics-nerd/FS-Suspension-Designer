classdef TestAntiRollBarWorker < matlab.unittest.TestCase
    properties
        Owner
        Project
    end
    methods(TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
            p=fsd.project.createEngineeringProject(struct('concept',fsd.project.createVehicleConcept(struct('id',"ARB_WORKER"))));
            [p,b]=fsd.project.registerAntiRollBar(p,antiRollBarInputs);
            d=b.definition; d.parameters.G_Pa=8e10; d.provenance.G_Pa=struct('sourceKind',"ASSUMED",'sourceNote',"Unconsumed material; physically identical equivalent model");
            [p,~]=fsd.project.registerAntiRollBar(p,d);
            d=b.definition; d.adjustmentId="OTHER_ADJUSTMENT"; [p,~]=fsd.project.registerAntiRollBar(p,d);
            d=b.definition; d.axleId="REAR"; d.id="REAR_BAR"; [p,~]=fsd.project.registerAntiRollBar(p,d);
            s=fsd.project.createEngineeringScenario(struct('id',"ARB_STUDY",'engine',"ARB_MECHANICAL", ...
                'scope',fsd.model.designScope('AXLE','FRONT'),'inputs',struct('arbId',b.definition.id,'arbRevision',1), ...
                'plan',struct('wheelTravel_m',[-.01,.01;0,0;.01,-.01])));
            p=fsdui.upsertScenario(p,s); t.Project=p;
            c=fsdui.Controller(p); t.Owner=c; t.addTeardown(@()finish(c)); c.enableWorker();
        end
    end
    methods(Test)
        function serialProcessAndMatPreserveExactArbEvidence(t)
            c=t.Owner; args=struct('scenarioId',"ARB_STUDY",'resultId',"ARB_WORKER_RESULT");
            serial=fsdui.Controller(t.Project); cleanup=onCleanup(@()serial.close()); serial.run('ARB_RUN',args,false);
            c.run('ARB_RUN',args,true); wait(c); t.assertEmpty(c.LastError);
            actual=c.LastValue.nativePayload; expected=serial.LastValue.nativePayload;
            t.verifyGreaterThanOrEqual(actual.study.elapsedTime_s,0); t.verifyGreaterThanOrEqual(expected.study.elapsedTime_s,0);
            actual.study=rmfield(actual.study,'elapsedTime_s'); expected.study=rmfield(expected.study,'elapsedTime_s');
            t.verifyEqual(actual,expected);
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); file=fullfile(folder.Folder,'worker.mat');
            before=c.Project; c.run('SAVE',struct('file',file,'overwrite',false),true); wait(c); t.assertEmpty(c.LastError);
            c.run('LOAD',struct('file',file),true); wait(c); t.assertEmpty(c.LastError); t.verifyEqual(c.Project,before);
        end
        function canonicalOtherRequestsAreRejectedAtomically(t)
            c=t.Owner;
            for mode=["REVISION","GRID","AXLE","ADJUSTMENT","OPTIONS","REFERENCE","PROVENANCE","OPERATION"]
                before=c.Project; epoch=c.Epoch; dirty=c.Dirty; file=c.File;
                c.run('ARB_RUN',struct('scenarioId',"ARB_STUDY",'resultId',"CROSSED_"+mode),true);
                q=fsdui.workerRequest(c.Operation); d=q.project.definition.scenarios{1}.definition;
                switch mode
                    case "REVISION", d.inputs.arbRevision=2;
                    case "GRID", d.plan.wheelTravel_m=flipud(d.plan.wheelTravel_m);
                    case "AXLE", d.scope=fsd.model.designScope('AXLE','REAR'); d.inputs=struct('arbId',"REAR_BAR",'arbRevision',1);
                    case "ADJUSTMENT", d.inputs.arbRevision=3;
                    case "OPTIONS", d.options=struct('MaxContinuationStep_m',.004);
                    case "PROVENANCE", d.description="Different requested provenance";
                    case "REFERENCE"
                        b=q.project.definition.resources.antiRollBars{1}.definition; b.referenceMode="DECLARED_FREE";
                        b.parameters.freeDeflection_m=.002; b.provenance.freeDeflection_m=struct('sourceKind',"KNOWN",'sourceNote',"Other free reference");
                        [q.project,b]=fsd.project.registerAntiRollBar(q.project,b); d.inputs.arbRevision=b.definition.revision;
                    case "OPERATION", q.action="READINESS";
                end
                q.project=fsdui.upsertScenario(q.project,fsd.project.createEngineeringScenario(d));
                response=fsdui.perform(q); t.verifyTrue(fsd.project.validateEngineeringProject(response.project));
                identifier='fsd:ui:SemanticMismatch'; if mode=="OPERATION", identifier='fsd:ui:OperationMismatch'; end
                t.verifyError(@()c.accept(response),identifier);
                t.verifyEqual(c.Project,before); t.verifyEqual(c.Epoch,epoch); t.verifyEqual(c.Dirty,dirty); t.verifyEqual(c.File,file);
                c.cancel(); wait(c); t.verifyEqual(c.Project,before);
            end
        end
        function reusableEquivalentRevisionCannotOwnNewExecution(t)
            [r,p]=fsd.project.runEngineeringScenario(t.Project,'ARB_STUDY','OLD_EXECUTION');
            d=p.definition.scenarios{1}.definition; d.inputs.arbRevision=2;
            other=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
            t.verifyEqual(fsd.project.resultCompatibility(r,other).status,"REUSABLE_DEPENDENCIES");
            c=t.Owner; before=c.Project; c.run('ARB_RUN',struct('scenarioId',"ARB_STUDY",'resultId',"OTHER_OWNER"),true);
            q=fsdui.workerRequest(c.Operation); d=q.project.definition.scenarios{1}.definition; d.inputs.arbRevision=2;
            q.project=fsdui.upsertScenario(q.project,fsd.project.createEngineeringScenario(d)); response=fsdui.perform(q);
            t.verifyError(@()c.accept(response),'fsd:ui:SemanticMismatch'); t.verifyEqual(c.Project,before); c.cancel(); wait(c);
        end
        function epochsAndCancellationPreserveProject(t)
            c=t.Owner; before=c.Project;
            for stage=["ENCODING","EXECUTING"]
                c.run('ARB_RUN',struct('scenarioId',"ARB_STUDY",'resultId',"STALE_ARB_"+stage),true);
                if stage=="EXECUTING", c.poll(); t.verifyEqual(c.TransportStage,"EXECUTING"); end
                c.invalidate(); wait(c); t.verifyEqual(c.Project,before); t.verifyTrue(contains(c.Status,'STALE'));
                c.run('ARB_RUN',struct('scenarioId',"ARB_STUDY",'resultId',"CANCEL_ARB_"+stage),true);
                if stage=="EXECUTING", c.poll(); t.verifyEqual(c.TransportStage,"EXECUTING"); end
                c.cancel(); wait(c); t.verifyEqual(c.Project,before);
            end
        end
        function nativeGeometryAndCoupledGlobalUseExistingWorker(t)
            [p,gd]=globalStaticGuidedInputs; [p,b]=fsd.project.registerAntiRollBar(p,geometricAntiRollBarInputs(p,'FRONT','ROCKER'));
            sd=struct('id',"NATIVE_ARB_WORKER",'engine',"ARB_MECHANICAL",'scope',fsd.model.designScope('AXLE','FRONT'), ...
                'inputs',struct('arbId',b.definition.id,'arbRevision',b.definition.revision), ...
                'plan',struct('wheelTravel_m',[-.005,.005;0,0;.005,-.005], ...
                'driverTravel_m',{{(-.02:.004:.02)',(-.02:.004:.02)'}}));
            p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(sd));
            p=fsd.project.assignAntiRollBars(p,{struct('axleId',"FRONT",'arbId',b.definition.id,'arbRevision',1)});
            gd.inputs.arbAxles="FRONT"; p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(gd));
            c=fsdui.Controller(p); cleanup=onCleanup(@()finish(c)); c.enableWorker();
            serial=fsdui.Controller(p); serialCleanup=onCleanup(@()serial.close());
            a=struct('scenarioId',sd.id,'resultId',"NATIVE_ARB_REPLY"); serial.run('ARB_RUN',a,false); c.run('ARB_RUN',a,true); wait(c);
            t.assertEmpty(c.LastError); t.verifyEqual(c.LastValue.nativePayload.study.responses,serial.LastValue.nativePayload.study.responses);
            a=struct('scenarioId',gd.id,'resultId',"COUPLED_GLOBAL_REPLY"); serial.run('GLOBAL_RUN',a,false); c.run('GLOBAL_RUN',a,true); wait(c);
            t.assertEmpty(c.LastError); actual=c.LastValue.nativePayload.equilibrium; expected=serial.LastValue.nativePayload.equilibrium;
            t.verifyEqual(actual.alternatives{1}.state,expected.alternatives{1}.state);
            globalRecord=c.LastValue;
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); file=fullfile(folder.Folder,'native-global.mat');
            before=c.Project; c.run('SAVE',struct('file',file,'overwrite',false),true); wait(c);
            c.run('LOAD',struct('file',file),true); wait(c); t.assertEmpty(c.LastError); t.verifyEqual(c.Project,before);
            unused=b.definition; unused.parameters.G_Pa=8e10;
            unused.provenance.G_Pa=struct('sourceKind',"ASSUMED",'sourceNote',"Unconsumed under independent known port stiffness");
            [other,revision]=fsd.project.registerAntiRollBar(before,unused);
            other=fsd.project.assignAntiRollBars(other,{struct('axleId',"FRONT",'arbId',revision.definition.id,'arbRevision',revision.definition.revision)});
            t.verifyEqual(fsd.project.resultCompatibility(globalRecord,other).status,"REUSABLE_DEPENDENCIES");
            c.run('GLOBAL_RUN',struct('scenarioId',gd.id,'resultId',"OTHER_GLOBAL_REVISION"),true);
            crossed=c.Operation; crossed.project=other; response=fsdui.perform(fsdui.workerRequest(crossed));
            t.verifyTrue(fsd.project.validateEngineeringProject(response.project));
            t.verifyError(@()c.accept(response),'fsd:ui:SemanticMismatch'); t.verifyEqual(c.Project,before); c.cancel(); wait(c);
        end
    end
end
function wait(c)
timer=tic; while c.Busy&&toc(timer)<180, pause(.05); c.poll(); end
assert(~c.Busy,'fsd:test:Timeout','Worker exceeded the observation window.');
end
function finish(c)
if ~isvalid(c), return; end
if c.Busy, c.cancel(); wait(c); end
c.close();
end
