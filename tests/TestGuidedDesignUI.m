classdef TestGuidedDesignUI < matlab.uitest.TestCase
    % Real native App Designer runtime, actual UI gestures and plotted graphics.
    properties
        App
        View
    end
    methods (TestClassSetup)
        function nativeApp(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'),fullfile(root,'app'));
            t.App=FSSuspensionDesigner(); t.View=t.App.UIFigure.UserData;
            t.View.UI.Async.Value=false;
            t.addTeardown(@()cleanup(t.View,t.App.UIFigure));
        end
    end
    methods (Test)
        function nativeClassAndNavigation(t)
            t.verifyClass(t.App,'FSSuspensionDesigner'); t.verifyNumElements(t.View.Tabs.Children,7);
            t.choose(t.View.UI.VehicleTab); t.verifyEqual(t.View.Tabs.SelectedTab,t.View.UI.VehicleTab);
            t.choose(t.View.UI.GeometryTab); t.verifyEqual(t.View.Tabs.SelectedTab,t.View.UI.GeometryTab);
        end
        function buildViaActualButton(t)
            t.View.Controller.run('DEMO',struct(),false);
            t.choose(t.View.UI.GeometryTab); t.press(t.View.UI.Build); drawnow;
            t.verifyEqual(t.View.Controller.LastValue.nativePayload.seed.nominalStatus,"VALID");
            t.verifySize(t.View.UI.Hardpoints.Data,[20 4]);
            t.verifyGreaterThan(numel(t.View.GeometryAxes.Children),20);
            original=t.View.Controller.Project;
            t.choose(t.View.UI.Scope,'FL'); drawnow; t.verifySize(t.View.UI.Hardpoints.Data,[10 4]);
            t.choose(t.View.UI.Scope,'FRONT'); drawnow; t.verifySize(t.View.UI.Hardpoints.Data,[20 4]);
            t.verifyEqual(t.View.Controller.Project,original,'View selection must not execute physics or revise the project.');
        end
        function bumpButtonAndStoredRedraw(t)
            c=t.View.Controller;
            if isempty(c.Project.definition.resources.geometries)
                c.run('DEMO',struct(),false); c.run('BUILD',struct('scope',"FRONT",'resultId',c.nextResultId()),false);
            end
            t.choose(t.View.UI.AnalysisTab);
            t.type(t.View.UI.Travel,'-0.01 0 0.01');
            t.press(t.View.UI.RunBump); drawnow;
            t.verifyEmpty(c.LastError); t.verifySize(t.View.UI.AnalysisTable.Data,[6 8]);
            before=c.Project; t.choose(t.View.UI.Metric,'toe_rad'); drawnow;
            t.verifyEqual(c.Project,before); t.verifyNotEmpty(t.View.UI.StateAxes.Children);
            t.choose(t.View.UI.AnalysisCorner,'FL'); drawnow; t.verifySize(t.View.UI.AnalysisTable.Data,[3 8]);
            t.choose(t.View.UI.AnalysisCorner,'FRONT'); drawnow; t.verifySize(t.View.UI.AnalysisTable.Data,[6 8]);
            t.verifyEqual(c.Project,before);
            c.run('READINESS',struct('scenarioId',"UI_BUILD_FRONT"),false);
            t.verifyError(@()c.run('READINESS',struct('scenarioId',"NO_SUCH_SCENARIO"),false),'fsd:project:MissingScenario');
            t.verifyTrue(contains(string(t.View.UI.Diagnostics.Value),'fsd:project:MissingScenario'));
        end
        function resizeKeepsControlsAndNativeXml(t)
            fig=t.App.UIFigure; fig.Position(3:4)=[1100 760]; drawnow;
            t.verifyTrue(isgraphics(t.View.UI.Build)); t.verifyTrue(isgraphics(t.View.UI.RunSearch));
            file=fullfile(fileparts(which('FSSuspensionDesigner')),'FSSuspensionDesigner.xml');
            t.verifyTrue(isfile(file)); t.verifyTrue(contains(fileread(file),'R2026b'));
            % Explicit FRONT independent -> mirrored transition must show FL,
            % not an empty FR editor after discarding the unused right set.
            t.View.UI.Scope.Value='FRONT'; t.View.Controller.run('DEMO',struct(),false);
            t.verifyEmpty(t.View.UI.Travel.Value,'A project without a stored plan must not inherit another project''s samples.');
            t.choose(t.View.UI.GeometryTab); t.choose(t.View.UI.Symmetry,'NONE');
            controls=findall(t.View.UI.GeometryTab,'Type','uibutton');
            apply=controls(string({controls.Text})=="Apply decisions");
            t.press(apply); t.choose(t.View.UI.Side,'FR');
            t.choose(t.View.UI.Symmetry,'MIRROR_FL'); t.press(apply);
            t.verifyEqual(string(t.View.UI.Side.Value),"FL");
            t.verifyNotEmpty(t.View.UI.DecisionTable.Data{1,2});
            t.choose(t.View.UI.ResultsTab); drawnow;
            t.verifyGreaterThan(t.View.ResultAxes.Position(4),100,'Plots must remain visible after resizing.');
            t.verifyEmpty(t.View.UI.Candidates.Data);
            t.verifyEmpty(t.View.ResultCurveAxes.Children,'Replacing a project must clear its old candidate curves.');
        end
        function synthesisComparisonAndWorkerNavigation(t)
            c=t.View.Controller;
            if isempty(c.Project.definition.resources.geometries)
                c.run('DEMO',struct(),false); c.run('BUILD',struct('scope',"FRONT",'resultId',c.nextResultId()),false);
            end
            c.enableWorker();
            c.run('REFERENCE_TARGETS',struct(),true); waitFor(c); t.assertEmpty(c.LastError);
            c.run('SYNTHESIS',struct('scenarioId',"UI_SEARCH_FL",'resultId',c.nextResultId()),true);
            t.verifyTrue(c.Busy); t.choose(t.View.UI.ResultsTab);
            t.verifyEqual(t.View.Tabs.SelectedTab,t.View.UI.ResultsTab);
            waitFor(c); t.assertEmpty(c.LastError); drawnow;
            t.verifyEqual(t.View.UI.Candidate.Value,c.LastValue.nativePayload.selectedIndex);
            % Timer polling remains active while the explicit waiter also polls.
            for k=1:3
                c.run('VALIDATE',struct(),true); t.choose(t.View.UI.ResultsTab);
                waitFor(c); t.assertEmpty(c.LastError);
            end
            t.verifySize(t.View.UI.Candidates.Data,[7 6]);
            t.verifyNotEmpty(t.View.ResultCurveAxes.Children); t.verifyNotEmpty(t.View.ResultAxes.Children);
            before=c.Project; t.choose(t.View.UI.ResultMetric,'toe_rad'); drawnow;
            t.verifyEqual(c.Project,before);
            root=fileparts(fileparts(mfilename('fullpath')));
            file=string(fullfile(root,'output','v018-ui-flow.mat'));
            c.run('SAVE',struct('file',file,'overwrite',true),true); waitFor(c);
            t.verifyEmpty(c.LastError); t.verifyFalse(c.Dirty);
        end
    end
end
function cleanup(view,fig)
view.shutdown(); if isgraphics(fig), delete(fig); end
end
function waitFor(c)
started=tic;
while c.Busy && toc(started)<180, c.poll(); pause(.05); end
assert(~c.Busy,'fsd:ui:TestTimeout','UI worker exceeded the bounded test timeout.');
end
