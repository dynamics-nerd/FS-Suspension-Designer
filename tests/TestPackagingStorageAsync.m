classdef TestPackagingStorageAsync < matlab.unittest.TestCase
    properties
        Controller
    end
    methods (TestClassSetup)
        function worker(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path; t.addTeardown(@()path(old));
            addpath(fullfile(root,'src'),fullfile(root,'app'));
            t.assumeTrue(logical(license('test','Distrib_Computing_Toolbox')));
            p=fsd.project.createEngineeringProject(struct('concept', ...
                fsd.project.createVehicleConcept(struct('id',"TRANSPORT_CASE")),'resources',struct('packaging',{{}})));
            t.Controller=fsdui.Controller(p); t.addTeardown(@()cleanup(t.Controller));
        end
    end
    methods (Test)
        function pureConversionActuallyWorksOnBackgroundPool(t)
            p=struct('project',t.Controller.Project,'missingText',[missing," a  "]);
            f=parfeval(backgroundPool,@fsd.project.encodeStorageValue,1,p); encoded=fetchOutputs(f);
            f=parfeval(backgroundPool,@fsd.project.decodeStorageValue,1,encoded); actual=fetchOutputs(f);
            t.verifyEqual(actual,p);
        end
        function graphConversionWorksOnBackgroundPool(t)
            item=struct('schemaVersion',"TEST",'kind',"VALUE",'data',[" a  ",missing], ...
                'array',single([0 -0.0 NaN]));
            original={item;item};
            f=parfeval(backgroundPool,@fsd.project.encodeStorageGraph,1,original); encoded=fetchOutputs(f);
            f=parfeval(backgroundPool,@fsd.project.decodeStorageGraph,1,encoded); actual=fetchOutputs(f);
            t.verifyEqual(actual,original); t.verifyEqual(1/actual{1}.array(2),single(-Inf));
            actual{1}.array(1)=1; t.verifyEqual(actual{2}.array(1),single(0));
        end
        function cancellationBeforeConversionDoesNotSubmitWork(t)
            c=t.Controller; ensureWorker(c); original=c.Project;
            c.run('VALIDATE',struct(),true);
            t.verifyEqual(c.TransportStage,"ENCODING"); t.verifyEmpty(c.Future);
            c.cancel(); c.poll();
            t.verifyFalse(c.Busy); t.verifyEmpty(c.LastError);
            t.verifyEqual(c.Project,original); t.verifyTrue(contains(c.Status,'cancelled'));
        end
        function conversionDispatchesCancellationButNotASecondWriter(t)
            % Enough pure metadata traversal to dispatch a delayed real timer
            % during conversion; no physical scenario is executed by this case.
            d=t.Controller.Project.definition;
            d.scenarios={fsd.project.createEngineeringScenario(struct('id',"COOPERATIVE_METADATA", ...
                'engine',"EXPLICITLY_UNSUPPORTED",'scope',fsd.model.designScope('CORNER','FL'), ...
                'inputs',struct('softwareOnlyValues',{num2cell(1:2000)})))};
            c=fsdui.Controller(fsd.project.createEngineeringProject(d)); c.enableWorker();
            t.addTeardown(@()cleanup(c)); original=c.Project;
            trigger=timer('ExecutionMode','singleShot','StartDelay',.01, ...
                'TimerFcn',@(~,~)interruptConversion(c,t));
            t.addTeardown(@()removeTimer(trigger));
            c.run('VALIDATE',struct(),true); start(trigger); c.poll();
            t.verifyEqual(trigger.TasksExecuted,1); t.verifyFalse(c.Busy);
            t.verifyEmpty(c.LastError); t.verifyEqual(c.Project,original);
            t.verifyTrue(contains(c.Status,'cancelled'));
        end
        function cancellationAtProcessStagePreservesForeignWork(t)
            c=t.Controller; ensureWorker(c); before=c.Project;
            foreign=parfeval(c.Pool,@pause,0,Inf); t.addTeardown(@()cancelForeign(foreign));
            c.run('VALIDATE',struct(),true); waitStage(c,"EXECUTING");
            c.cancel(); waitFinished(c);
            t.verifyEqual(c.Project,before); t.verifyTrue(contains(c.Status,'cancelled'));
            t.verifyNotEqual(string(foreign.State),"finished"); cancelForeign(foreign);
        end
        function staleDuringDecodeCannotPublishSave(t)
            c=t.Controller; ensureWorker(c); folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            file=string(fullfile(folder.Folder,'not-published.mat'));
            c.run('SAVE',struct('file',file,'overwrite',false),true);
            temporary=c.Operation.arguments.temporaryFile;
            waitStage(c,"DECODING"); t.verifyTrue(isfile(temporary)); c.invalidate(); waitFinished(c);
            t.verifyFalse(isfile(file)); t.verifyFalse(isfile(temporary)); t.verifyTrue(startsWith(c.Status,'STALE'));
        end
    end
end
function waitStage(c,stage)
started=tic;
while c.Busy && c.TransportStage~=stage && toc(started)<120, c.poll(); pause(.02); end
assert(c.Busy && c.TransportStage==stage,'fsd:ui:TestTimeout','Expected transport stage was not reached.');
end
function waitFinished(c)
started=tic;
while c.Busy && toc(started)<120, c.poll(); pause(.02); end
assert(~c.Busy,'fsd:ui:TestTimeout','Transport did not complete.');
end
function cleanup(c)
if c.Busy, c.cancel(); waitFinished(c); end
c.close();
end
function cancelForeign(f)
if isvalid(f), cancel(f); wait(f); end
end
function interruptConversion(c,t)
t.verifyTrue(c.Busy);
t.verifyError(@()c.run('NEW',struct('id',"MUST_NOT_REENTER"),true),'fsd:ui:Busy');
c.poll(); % Completion guard must not schedule a second conversion/worker.
t.verifyEmpty(c.Future); t.verifyEqual(c.TransportStage,"ENCODING");
c.cancel();
end
function removeTimer(value)
if isvalid(value), stop(value); delete(value); end
end
function ensureWorker(c)
if isempty(c.Pool), c.enableWorker(); end
end
