classdef TestPackagingUI < matlab.uitest.TestCase
    % Real native app, explicit illustrative solids and actual engineering APIs.
    methods (Test)
        function completeStaticBumpRevisionMatAndCandidateFlow(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
            app=FSSuspensionDesigner(); view=app.UIFigure.UserData;
            fig=app.UIFigure; % Capture the graphics handle before the app is deliberately closed.
            t.addTeardown(@()closeApp(view,fig)); view.UI.Async.Value=false;
            c=view.Controller; c.run('DEMO',struct(),false);
            t.choose(view.UI.GeometryTab); t.press(view.UI.Build); drawnow;
            t.assertEmpty(c.LastError);
            % Explicit fixture request supplies every physical dimension; UI
            % table editing/Apply thereafter uses exactly the production path.
            c.run('PACKAGING_DEMO',struct('cornerId',"FL"),false);
            t.choose(view.UI.PackagingTab); ui=view.Packaging.UI;
            t.choose(ui.EditorSelector,'Volumes'); drawnow;
            t.assertEqual(ui.Volumes.ColumnEditable,true(1,15));
            fprintf('PACK_UI_STEP editors\n');
            beforeApply=c.Project;
            t.type(ui.Volumes,[1 6],'0.004'); t.press(ui.Apply); drawnow;
            t.verifyEqual(c.Project,beforeApply); t.verifyEqual(ui.Apply.Text,'Apply definitions');
            % Explicit different software-only radius, not a vehicle default.
            t.type(ui.Volumes,[1 6],'0.0045'); t.press(ui.Apply); drawnow;
            t.verifyNotEqual(c.Project,beforeApply);
            t.assertEmpty(c.LastError); t.press(ui.Nominal); drawnow;
            nominal=c.LastValue{1}; t.verifyEqual(nominal.nativePayload.status,"CLEAR_SAMPLED");
            fprintf('PACK_UI_STEP nominal\n');
            t.choose(view.UI.AnalysisTab); t.type(view.UI.Travel,'-0.01 0 0.01');
            t.press(view.UI.RunBump); drawnow; t.assertEmpty(c.LastError);
            parents=c.LastValue; parent=parents{1};
            t.choose(view.UI.PackagingTab); t.choose(ui.Parent,char(parent.id));
            t.press(ui.Bump); drawnow; t.assertEmpty(c.LastError);
            result=c.LastValue{1}; t.verifyEqual(result.nativePayload.status,"COLLISION_DETECTED");
            fprintf('PACK_UI_STEP sampled\n');
            t.verifyEqual(size(ui.Checks.Data,1),3); t.verifyTrue(isfinite(result.nativePayload.minimumObservedDistance_m));
            t.verifyEqual(view.Packaging.Axes.UserData.sampleIndex,3);
            t.choose(ui.Checks,[3 1]); drawnow;
            t.verifyEqual(view.Packaging.Axes.UserData.pairStatus,"COLLISION_DETECTED");
            t.choose(ui.Sample,'1'); drawnow; t.verifyEqual(view.Packaging.Axes.UserData.sampleIndex,1);
            t.choose(ui.Checks,[1 3]); drawnow;
            t.verifyEqual(view.Packaging.Axes.UserData.sampleIndex,1);
            t.choose(ui.Filter,'ISSUES'); t.verifyLessThan(size(ui.Checks.Data,1),3);
            t.choose(ui.Checks,[1 3]); drawnow;
            t.verifyEqual(view.Packaging.Axes.UserData.sampleIndex,3);
            t.verifyEqual(view.Packaging.Axes.UserData.pairStatus,"COLLISION_DETECTED");
            t.choose(ui.Filter,'ALL');
            before=c.Project;
            position=fsdui.numberList(ui.Volumes.Data{2,7}); position(3)=position(3)+1;
            t.type(ui.Volumes,[2 7],char(join(compose('%.17g',position),' '))); t.press(ui.Apply); drawnow;
            t.assertEmpty(c.LastError);
            compatibility=fsd.project.resultCompatibility(result,c.Project); t.verifyEqual(compatibility.status,"STALE");
            compatibility=fsd.project.resultCompatibility(parent,c.Project); t.verifyEqual(compatibility.status,"REUSABLE_DEPENDENCIES");
            t.verifyEqual(c.Project.definition.results,before.definition.results);
            t.verifyEqual(ui.Status.UserData.compatibility,"STALE");
            t.press(ui.Bump); drawnow; t.assertEmpty(c.LastError);
            t.verifyEqual(c.LastValue{1}.nativePayload.status,"CLEAR_SAMPLED");
            fprintf('PACK_UI_STEP staleAndRecalculated\n');
            c.run('REFERENCE_TARGETS',struct(),false);
            c.run('SYNTHESIS',struct('scenarioId',"UI_SEARCH_FL",'resultId',c.nextResultId()),false);
            synthesis=c.LastValue; unchanged=synthesis.nativePayload;
            t.choose(ui.Parent,char(synthesis.id)); t.choose(ui.Selection,'CANDIDATE');
            ui.Candidate.Value=synthesis.nativePayload.selectedIndex;
            t.press(ui.Compare); drawnow; t.assertEmpty(c.LastError);
            records=c.LastValue; t.verifyNumElements(records,2);
            t.verifyEqual(records{1}.scenarioAtExecution.definition.inputs.selection,"SEED");
            t.verifyEqual(records{2}.scenarioAtExecution.definition.inputs.selection,"CANDIDATE");
            t.verifyEqual(synthesis.nativePayload,unchanged);
            fprintf('PACK_UI_STEP compared\n');
            t.verifyGreaterThanOrEqual(size(ui.Comparison.Data,1),5);
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            file=string(fullfile(folder.Folder,'guided-packaging.mat'));
            snapshot=c.Project; %#ok<NASGU> WHOS measures the full pre-save value, not the Controller handle.
            info=whos('snapshot'); fprintf('PACK_UI_PROJECT_BYTES=%d\n',info.bytes); clear snapshot;
            c.run('SAVE',struct('file',file,'overwrite',false),false); saved=c.Project;
            fprintf('PACK_UI_STEP saved SECONDS=%.6f\n',c.LastElapsed_s);
            % Preserve the actual completed native case before the temporary
            % fixture is removed, for reproducible capacity/transport profiling.
            copyfile(file,fullfile(root,'output','v019-packaging-ui-full-history.mat'));
            closeApp(view,app.UIFigure);
            t.verifyEmpty(view.Controller);
            clear c view app beforeApply before nominal parents parent result synthesis unchanged records;
            reopened=FSSuspensionDesigner(); v2=reopened.UIFigure.UserData;
            reopenedFigure=reopened.UIFigure;
            t.addTeardown(@()closeApp(v2,reopenedFigure));
            v2.Controller.run('LOAD',struct('file',file),false); drawnow;
            t.verifyEqual(v2.Controller.Project,saved);
            clear saved; % Exact round-trip oracle has served its final assertion.
            t.choose(v2.UI.PackagingTab);
            t.verifyGreaterThanOrEqual(size(v2.Packaging.UI.Comparison.Data,1),5);
            fprintf('PACK_UI_STEP reopened\n');
            worker=v2.Controller; worker.enableWorker(); v2.UI.Async.Value=true;
            navigatedExecution=false; navigatedDecode=false;
            originalChanged=worker.Changed;
            % Observe the actual transition while Controller's completion guard
            % owns it. The active UI timer may otherwise decode a small graph
            % before the explicit waiter samples TransportStage again. Keep
            % the timer active and perform a real UITest navigation, not a
            % callback substitution or an artificial delay in production.
            worker.Changed=@transportChanged;
            callbackGuard=onCleanup(@()restoreChanged(worker,originalChanged));
            ticBytes(worker.Pool); operationStarted=tic;
            t.press(v2.Packaging.UI.Nominal); t.verifyTrue(worker.Busy);
            t.choose(v2.UI.VehicleTab); t.verifyEqual(v2.Tabs.SelectedTab,v2.UI.VehicleTab);
            started=tic;
            % Software wait budget, not a numerical tolerance. The measured
            % full-history comparison costs504s; allow slow validated I/O too.
            while worker.Busy && toc(started)<1200
                worker.poll();
                if worker.TransportStage=="EXECUTING" && ~navigatedExecution
                    t.choose(v2.UI.PackagingTab); t.verifyEqual(v2.Tabs.SelectedTab,v2.UI.PackagingTab);
                    navigatedExecution=true; fprintf('PACK_UI_NAV executing\n');
                end
                pause(.05);
            end
            t.assertFalse(worker.Busy); t.assertEmpty(worker.LastError);
            t.verifyTrue(navigatedExecution); t.verifyTrue(navigatedDecode);
            t.verifyEqual(worker.LastValue{1}.nativePayload.status,"CLEAR_SAMPLED");
            transfer=tocBytes(worker.Pool); disp(transfer);
            fprintf('PACK_UI_WORKER wall=%.6f worker=%.6f\n',toc(operationStarted),worker.LastElapsed_s);
            fprintf('PACK_UI_STEP asynchronousNavigation\n');
            function transportChanged()
                originalChanged();
                if worker.Busy && worker.TransportStage=="DECODING" && ~navigatedDecode
                    navigatedDecode=true;
                    t.choose(v2.UI.VehicleTab);
                    t.verifyEqual(v2.Tabs.SelectedTab,v2.UI.VehicleTab);
                    fprintf('PACK_UI_NAV decoding\n');
                end
            end
        end
    end
end
function closeApp(view,fig)
if isgraphics(fig), view.shutdown(); delete(fig); end
end
function restoreChanged(controller,callback)
controller.Changed=callback;
end
