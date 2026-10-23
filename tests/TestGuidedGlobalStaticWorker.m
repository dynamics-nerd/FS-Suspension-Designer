classdef TestGuidedGlobalStaticWorker < matlab.unittest.TestCase
    properties
        Owner
        Configured
        Definition
    end
    methods(TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
            [p,d]=globalStaticGuidedInputs(); c=fsdui.Controller(p); t.Owner=c; t.addTeardown(@()finish(c));
            c.run('GLOBAL_CONFIG',struct('definition',d),false); t.Configured=c.Project; t.Definition=d;
            c.enableWorker(); f=parfeval(c.Pool,@feature,1,'getpid'); fprintf('GLOBAL_WORKER_PID=%d\n',fetchOutputs(f));
        end
    end
    methods(Test)
        function realWorkerNativeSolveAndMat(t)
            c=t.Owner; serial=fsdui.Controller(t.Configured); cleanup=onCleanup(@()serial.close());
            a=struct('scenarioId',t.Definition.id,'resultId',"GLOBAL_WORKER");
            serial.run('GLOBAL_RUN',a,false); c.run('GLOBAL_RUN',a,true); wait(c); t.assertEmpty(c.LastError);
            x=c.LastValue; y=serial.LastValue;
            t.verifyEqual(x.prepared,y.prepared); t.verifyEqual(x.nativePayload.equilibrium.status,y.nativePayload.equilibrium.status);
            t.verifyEqual(x.nativePayload.equilibrium.alternatives{1}.state,y.nativePayload.equilibrium.alternatives{1}.state);
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); file=fullfile(folder.Folder,'worker-global.mat');
            before=c.Project; c.run('SAVE',struct('file',file,'overwrite',false),true); wait(c); t.assertEmpty(c.LastError);
            c.run('LOAD',struct('file',file),true); wait(c); t.assertEmpty(c.LastError); t.verifyEqual(c.Project,before);
        end
        function cancellationDoesNotPublishPartialCorners(t)
            c=t.Owner; before=c.Project;
            c.run('GLOBAL_RUN',struct('scenarioId',t.Definition.id,'resultId',"CANCEL_GLOBAL"),true);
            c.poll(); t.verifyEqual(c.TransportStage,"EXECUTING"); c.cancel(); wait(c);
            t.verifyEqual(c.Project,before); t.verifyTrue(contains(c.Status,'cancelled'));
        end
        function changedEpochDiscardsCompleteWorkerResult(t)
            c=t.Owner; before=c.Project;
            c.run('GLOBAL_RUN',struct('scenarioId',t.Definition.id,'resultId',"STALE_GLOBAL"),true);
            c.invalidate(); wait(c); t.verifyEqual(c.Project,before); t.verifyTrue(contains(c.Status,'STALE'));
        end
        function canonicalOtherVehicleResponseRejectedAtomically(t)
            c=t.Owner; before=c.Project;
            a=struct('scenarioId',t.Definition.id,'resultId',"WRONG_VEHICLE"); c.run('GLOBAL_RUN',a,true);
            q=fsdui.workerRequest(c.Operation); d=t.Definition; d.plan.systemOptions.roadHeight_m=.001;
            q.project=fsdui.upsertScenario(q.project,fsd.project.createEngineeringScenario(d));
            response=fsdui.perform(q); t.verifyTrue(fsd.project.validateEngineeringProject(response.project));
            t.verifyError(@()c.accept(response),'fsd:ui:SemanticMismatch'); t.verifyEqual(c.Project,before);
            c.cancel(); wait(c); t.verifyEqual(c.Project,before);
        end
    end
end
function wait(c)
timer=tic;
while c.Busy && toc(timer)<600, pause(.05); c.poll(); end
assert(~c.Busy,'fsd:test:Timeout','Global worker did not finish within test observation window.');
end
function finish(c)
if ~isvalid(c), return; end
if c.Busy, c.cancel(); wait(c); end
c.close();
end
