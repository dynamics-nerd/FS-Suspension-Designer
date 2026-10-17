classdef TestGuidedDesignAsync < matlab.unittest.TestCase
    % Process isolation, revision guards and cancellation; no parallel native search.
    properties
        Controller
    end
    methods (TestClassSetup)
        function worker(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'),fullfile(root,'app'));
            t.assumeTrue(logical(license('test','Distrib_Computing_Toolbox')));
            t.Controller=fsdui.Controller(); t.Controller.enableWorker();
            t.verifyClass(t.Controller.Pool,'parallel.ProcessPool');
            t.addTeardown(@()cleanup(t.Controller));
        end
    end
    methods (Test)
        function sequentialSnapshotMatchesWorker(t)
            c=t.Controller; c.run('DEMO',struct(),true); waitFor(c);
            serial=fsdui.Controller(); serial.run('DEMO',struct(),false);
            t.addTeardown(@()serial.close()); t.verifyEmpty(c.LastError);
            t.verifyEqual(c.Project,serial.Project);
        end
        function editedEpochDiscardsReturn(t)
            c=t.Controller; original=c.Project;
            c.run('NEW',struct('id',"SHOULD_NOT_REPLACE"),true); c.invalidate(); waitFor(c);
            t.verifyEqual(c.Project,original); t.verifyTrue(startsWith(c.Status,'STALE'));
        end
        function singleWriterAndCloseGuard(t)
            c=t.Controller; c.run('VALIDATE',struct(),true);
            t.verifyError(@()c.run('DEMO',struct(),true),'fsd:ui:Busy');
            t.verifyError(@()c.close(),'fsd:ui:Busy'); waitFor(c);
            pool=c.Pool; owned=c.OwnPool;
            foreign=parfeval(pool,@pause,0,Inf); % Software lifecycle sentinel, not physics.
            t.addTeardown(@()cancelIfValid(foreign));
            c.close(); t.verifyTrue(isvalid(pool),'Closing one session must not abort borrowed work.');
            cancel(foreign); wait(foreign);
            if owned && isvalid(pool), delete(pool); end % Only the pool this test actually created.
            c.enableWorker(); % Restore the fixture without deleting a user's preexisting pool.
        end
        function cancellationWaitsForCompletion(t)
            c=t.Controller; original=c.Project; c.run('NEW',struct('id',"CANCELLED_PROJECT"),true);
            c.cancel(); waitFor(c);
            t.verifyEqual(c.Project,original); t.verifyFalse(c.Busy);
            t.verifyTrue(contains(c.Status,'cancelled'));
        end
        function workerErrorDoesNotMutateProject(t)
            c=t.Controller; original=c.Project;
            c.run('READINESS',struct('scenarioId',"NO_SUCH_SCENARIO"),true); waitFor(c);
            t.verifyNotEmpty(c.LastError); t.verifyEqual(c.Project,original);
        end
        function staleSaveDoesNotPublishTemp(t)
            c=t.Controller; file=string(tempname)+".mat";
            t.addTeardown(@()removeFile(file));
            c.run('SAVE',struct('file',file,'overwrite',false),true);
            temporary=c.Operation.arguments.temporaryFile; c.invalidate(); waitFor(c);
            t.verifyFalse(isfile(file)); t.verifyFalse(isfile(temporary));
        end
        function nativeSearchAndMatOnWorker(t)
            c=t.Controller; c.run('DEMO',struct(),true); waitFor(c);
            c.run('BUILD',struct('scope',"FRONT",'resultId',c.nextResultId()),true); waitFor(c);
            t.assertEmpty(c.LastError);
            c.run('REFERENCE_TARGETS',struct(),true); waitFor(c); t.assertEmpty(c.LastError);
            c.run('SYNTHESIS',struct('scenarioId',"UI_SEARCH_FL",'resultId',c.nextResultId()),true);
            t.verifyTrue(c.Busy); waitFor(c); t.assertEmpty(c.LastError);
            r=c.LastValue.nativePayload;
            t.verifyEqual(r.search.evaluationCount,7); t.verifyEqual(r.statistics.physicalBumpSweeps,7);
            t.verifyEqual(r.search.records{1}.score,.101722096447,'AbsTol',1e-12);
            t.verifyEqual(r.search.records{r.selectedIndex}.score,0);
            file=string(tempname)+".mat"; t.addTeardown(@()removeFile(file));
            c.run('SAVE',struct('file',file,'overwrite',false),true); waitFor(c); t.assertEmpty(c.LastError);
            original=c.Project; c.run('LOAD',struct('file',file),true); waitFor(c);
            t.verifyEmpty(c.LastError); t.verifyEqual(c.Project,original);
        end
    end
end
function waitFor(c)
timer=tic;
while c.Busy && toc(timer)<120, c.poll(); pause(.05); end
assert(~c.Busy,'fsd:ui:TestTimeout','Worker did not complete within the test timeout.');
end
function cleanup(c)
if c.Busy, c.cancel(); waitFor(c); end
c.close();
end
function removeFile(file)
if isfile(file), delete(file); end
end
function cancelIfValid(future)
if isvalid(future), cancel(future); end
end
