classdef TestGuidedActuationPersistence < matlab.unittest.TestCase
    properties
        Project
        Configured
        Owner
    end
    methods(TestClassSetup)
        function inputs(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
            [t.Project,args]=guidedActuationFixture(); c=fsdui.Controller(t.Project);
            cleanup=onCleanup(@()c.close()); c.run('ACTUATION_CONFIG',args,false); t.Configured=c.Project;
            t.Owner=fsdui.Controller(t.Configured); t.addTeardown(@()finish(t.Owner));
            t.assertTrue(logical(license('test','Distrib_Computing_Toolbox')),'Real process-worker verification requires PCT.');
            t.Owner.enableWorker();
            f=parfeval(t.Owner.Pool,@feature,1,'getpid'); pid=fetchOutputs(f);
            fprintf('OWNED_WORKER_PID=%d\n',pid);
        end
    end
    methods(Test)
        function workerAndSerialPhysicalEvidenceMatch(t)
            a=args(); serial=fsdui.Controller(t.Configured); cleanup=onCleanup(@()serial.close());
            serial.run('ACTUATION_RUN',a,false); c=t.Owner;
            c.run('NEW',struct('id',"TEMPORARY"),false);
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            file=fullfile(folder.Folder,'configured.mat'); fsd.project.saveEngineeringProject(t.Configured,file,false);
            c.run('LOAD',struct('file',file),true); waitFor(c); t.assertEmpty(c.LastError);
            c.run('ACTUATION_RUN',a,true); waitFor(c); t.assertEmpty(c.LastError);
            t.verifyEqual(c.LastValue.prepared,serial.LastValue.prepared);
            x=c.LastValue.nativePayload; y=serial.LastValue.nativePayload;
            t.verifyEqual(x.sweep.damperCompression_m,y.sweep.damperCompression_m);
            t.verifyEqual(x.sweep.rockerAngle_rad,y.sweep.rockerAngle_rad);
            t.verifyEqual(x.analysis.damperMotionRatio,y.analysis.damperMotionRatio);
            t.verifyEqual(x.analysis.springAxialForce_N,y.analysis.springAxialForce_N);
            t.verifyEqual(x.analysis.damperAxialResistance_N,y.analysis.damperAxialResistance_N);
            t.verifyEqual(x.analysis.wheelRateTotal_N_per_m,y.analysis.wheelRateTotal_N_per_m);
            expected=c.Project; destination=fullfile(folder.Folder,'worker-history.mat');
            c.run('SAVE',struct('file',destination,'overwrite',false),true); waitFor(c); t.assertEmpty(c.LastError);
            c.run('LOAD',struct('file',destination),true); waitFor(c); t.assertEmpty(c.LastError);
            t.verifyEqual(c.Project,expected);
        end
        function processCancellationDoesNotApplyPartialRecords(t)
            c=t.Owner; before=c.Project; a=args(); a.resultId="CANCELLED_ANALYSIS";
            c.run('ACTUATION_RUN',a,true); c.poll(); t.verifyEqual(c.TransportStage,"EXECUTING");
            c.cancel(); waitFor(c); t.verifyEqual(c.Project,before);
            t.verifyTrue(contains(c.Status,'cancelled')); t.verifyFalse(c.Busy);
        end
        function workerSynthesisAdoptionAndCompleteLedgerRoundTrip(t)
            [~,~,s,options]=guidedActuationFixture(); c=t.Owner;
            d=struct('id',"UI_ACT_SEARCH_FL",'engine',"ACTUATION_SYNTHESIS", ...
                'scope',fsd.model.designScope('CORNER','FL'),'specification',s.specification, ...
                'plan',s.plan,'options',options);
            c.run('SPECIFICATION',struct('definition',d),true); waitFor(c); t.assertEmpty(c.LastError);
            before=c.Project; started=tic;
            c.run('SYNTHESIS',struct('scenarioId',"UI_ACT_SEARCH_FL",'resultId',"WORKER_SEARCH"),true);
            waitFor(c); fprintf('WORKER_ACT_SYNTHESIS_TOTAL_S=%.6f\n',toc(started)); t.assertEmpty(c.LastError);
            search=c.LastValue; records=search.nativePayload.search.records;
            index=find(cellfun(@(e)e.eligible && ~isempty(e.changes),records),1); t.assertNotEmpty(index);
            ledger=c.Project.definition.results; started=tic;
            c.run('ACTUATION_ADOPT',struct('resultId',search.id,'index',index),true);
            waitFor(c); fprintf('WORKER_ACT_ADOPT_TOTAL_S=%.6f\n',toc(started)); t.assertEmpty(c.LastError);
            t.verifyEqual(c.Project.definition.resources.geometries,before.definition.resources.geometries);
            t.verifyEqual(c.Project.definition.resources.actuations{1},records{index}.actuation);
            t.verifyEqual(c.Project.definition.resources.mechanicals{1},records{index}.mechanical);
            t.verifyEqual(c.Project.definition.results,ledger);
            for j=1:numel(before.definition.results)
                t.verifyTrue(any(cellfun(@(r)isequaln(r,before.definition.results{j}),ledger)));
            end
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            file=fullfile(folder.Folder,'worker-synthesis-adopted.mat'); expected=c.Project;
            c.run('SAVE',struct('file',file,'overwrite',false),true); waitFor(c); t.assertEmpty(c.LastError);
            c.run('LOAD',struct('file',file),true); waitFor(c); t.assertEmpty(c.LastError);
            t.verifyEqual(c.Project,expected);
        end
        function ownerEditDiscardsOtherwiseValidWorkerResult(t)
            c=t.Owner; before=c.Project; a=args(); a.resultId="OBSOLETE_ANALYSIS";
            c.run('ACTUATION_RUN',a,true); c.invalidate(); waitFor(c);
            t.verifyEqual(c.Project,before); t.verifyTrue(contains(c.Status,'STALE'));
        end
        function semanticRejectionLeavesCompleteOwnerUnchanged(t)
            c=t.Owner; before=c.Project; a=args(); a.resultId="BOUND_ANALYSIS";
            c.run('ACTUATION_RUN',a,true);
            q=fsdui.workerRequest(c.Operation); q.arguments.plan.travel_m=[-.005;0;.005];
            r=fsdui.perform(q); fsd.project.validateEngineeringProject(r.project);
            epoch=c.Epoch; last=c.LastValue; operation=c.Operation;
            t.verifyError(@()c.accept(r),'fsd:ui:SemanticMismatch');
            t.verifyEqual(c.Project,before); t.verifyEqual(c.Epoch,epoch);
            t.verifyEqual(c.LastValue,last); t.verifyEqual(c.Operation,operation);
            c.cancel(); waitFor(c);
        end
        function fullGuidedExampleRoundTripsAndKeepsHistoricalStates(t)
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            out=guidedActuationMechanicsExample(fullfile(folder.Folder,'complete.mat'));
            for stage=out.stages
                fprintf('GUIDED_STAGE=%s SECONDS=%.6f MATLAB_BYTES_AFTER=%.0f\n', ...
                    stage.action,stage.elapsed_s,stage.matlabBytesAfter);
            end
            if ~isempty(out.memoryBefore)
                fprintf('GUIDED_MEMORY_BEFORE=%.0f AFTER=%.0f\n',out.memoryBefore.MemUsedMATLAB,out.memoryAfter.MemUsedMATLAB);
            end
            t.verifyNumElements(out.project.definition.results,4);
            reports=fsd.project.resultCompatibilities(out.project); ids=cellfun(@(r)string(r.id),out.project.definition.results);
            t.verifyEqual(reports{ids=="UNCHANGED_GEOMETRY_FL"}.status,"REUSABLE_DEPENDENCIES");
            t.verifyEqual(reports{ids=="MECH"}.status,"STALE");
            t.verifyEqual(reports{ids=="SEARCH"}.status,"STALE");
            t.verifyEqual(out.search.nativePayload.search.records{out.search.nativePayload.selectedIndex}.score,0);
        end
    end
end
function a=args()
a=struct('cornerId',"FL",'engine',"MECHANICAL",'plan',fsdui.actuationPlan('-10 0 10','0',true),'resultId',"WORKER_MECH");
end
function waitFor(c)
started=tic;
while c.Busy && toc(started)<600, c.poll(); pause(.05); end
assert(~c.Busy,'fsd:tests:ObservationBudget','The finite QA observation budget expired; no PASS is claimed.');
end
function finish(c)
if c.Busy, c.cancel(); waitFor(c); end
c.close();
end
