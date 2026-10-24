classdef TestTireWorker < matlab.unittest.TestCase
    properties
        Owner
        Project
    end
    methods(TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
            [d,s,q]=tireCharacterizationInputs;
            p=fsd.project.createEngineeringProject(struct('concept',fsd.project.createVehicleConcept(struct('id',"TIRE_WORKER"))));
            [p,tire]=fsd.project.registerTire(p,d); d.force.parameters.mu0=1.1; [p,~]=fsd.project.registerTire(p,d);
            scenario=fsd.project.createEngineeringScenario(struct('id',"TIRE_STUDY",'engine',"TIRE_CHARACTERIZATION", ...
                'scope',fsd.model.designScope('VEHICLE','VEHICLE'),'inputs',struct('tireId',tire.definition.id,'tireRevision',1), ...
                'plan',struct('states',s,'request',q)));
            p=fsdui.upsertScenario(p,scenario); t.Project=p;
            c=fsdui.Controller(p); t.Owner=c; t.addTeardown(@()finish(c)); c.enableWorker();
        end
    end
    methods(Test)
        function serialProcessAndMatAreExact(t)
            c=t.Owner; a=struct('scenarioId',"TIRE_STUDY",'resultId',"TIRE_WORKER_RESULT");
            serial=fsdui.Controller(t.Project); cleanup=onCleanup(@()serial.close()); serial.run('TIRE_RUN',a,false);
            c.run('TIRE_RUN',a,true); wait(c); t.assertEmpty(c.LastError);
            t.verifyEqual(c.LastValue.nativePayload,serial.LastValue.nativePayload);
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); file=fullfile(folder.Folder,'worker.mat');
            before=c.Project; c.run('SAVE',struct('file',file,'overwrite',false),true); wait(c); t.assertEmpty(c.LastError);
            c.run('LOAD',struct('file',file),true); wait(c); t.assertEmpty(c.LastError); t.verifyEqual(c.Project,before);
        end
        function canonicalDifferentRequestsAreRejectedAtomically(t)
            c=t.Owner;
            for mode=["REVISION","CHANNELS","GRID","POLICY"]
                before=c.Project;
                c.run('TIRE_RUN',struct('scenarioId',"TIRE_STUDY",'resultId',"WRONG_"+mode),true);
                q=fsdui.workerRequest(c.Operation); d=q.project.definition.scenarios{1}.definition;
                switch mode
                    case "REVISION", d.inputs.tireRevision=2;
                    case "CHANNELS", d.plan.request.channels="Fy";
                    case "GRID", d.plan.states.alpha_rad=flipud(d.plan.states.alpha_rad);
                    case "POLICY", d.plan.request.domainPolicy="REJECT";
                end
                q.project=fsdui.upsertScenario(q.project,fsd.project.createEngineeringScenario(d));
                received=fsdui.perform(q); t.verifyTrue(fsd.project.validateEngineeringProject(received.project));
                t.verifyError(@()c.accept(received),'fsd:ui:SemanticMismatch'); t.verifyEqual(c.Project,before);
                c.cancel(); wait(c); t.verifyEqual(c.Project,before);
            end
        end
        function epochAndCancellationRetainHistory(t)
            c=t.Owner; before=c.Project;
            c.run('TIRE_RUN',struct('scenarioId',"TIRE_STUDY",'resultId',"STALE_TIRE"),true);
            c.invalidate(); wait(c); t.verifyEqual(c.Project,before); t.verifyTrue(contains(c.Status,'STALE'));
            c.run('TIRE_RUN',struct('scenarioId',"TIRE_STUDY",'resultId',"CANCEL_TIRE"),true);
            c.cancel(); wait(c); t.verifyEqual(c.Project,before);
        end
        function reusableOtherRevisionStillCannotOwnWorkerReply(t)
            p=t.Project; d=p.definition.resources.tires{1}.definition; d.force.parameters.Ckappa_N=17000;
            [p,tire]=fsd.project.registerTire(p,d); sd=p.definition.scenarios{1}.definition;
            sd.plan.request.channels="Fy"; p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(sd));
            [r,p]=fsd.project.runEngineeringScenario(p,sd.id,'PREVIOUS_LATERAL');
            alternate=sd; alternate.inputs.tireRevision=tire.definition.revision;
            other=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(alternate));
            t.verifyEqual(fsd.project.resultCompatibility(r,other).status,"REUSABLE_DEPENDENCIES");
            c=fsdui.Controller(p); cleanup=onCleanup(@()finish(c)); c.enableWorker(); before=c.Project;
            c.run('TIRE_RUN',struct('scenarioId',sd.id,'resultId',"CROSSED_REUSABLE_REVISION"),true);
            q=fsdui.workerRequest(c.Operation); q.project=other;
            received=fsdui.perform(q); t.verifyTrue(fsd.project.validateEngineeringProject(received.project));
            t.verifyError(@()c.accept(received),'fsd:ui:SemanticMismatch'); t.verifyEqual(c.Project,before);
            c.cancel(); wait(c); t.verifyEqual(c.Project,before);
        end
    end
end
function wait(c)
timer=tic; while c.Busy&&toc(timer)<180, pause(.05); c.poll(); end
assert(~c.Busy,'fsd:test:Timeout','Worker exceeded the test observation window.');
end
function finish(c)
if ~isvalid(c), return; end
if c.Busy, c.cancel(); wait(c); end
c.close();
end
