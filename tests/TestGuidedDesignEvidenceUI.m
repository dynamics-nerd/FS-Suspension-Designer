classdef TestGuidedDesignEvidenceUI < matlab.uitest.TestCase
    properties
        Folder
        BaseFile
        SearchFile
        App
        View
    end
    properties (TestParameter)
        ChangedGroup={'UCA','Upright'}
    end
    methods (TestClassSetup)
        function nativeCases(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); t.Folder=folder.Folder;
            t.BaseFile=string(fullfile(t.Folder,'base.mat')); t.SearchFile=string(fullfile(t.Folder,'search.mat'));
            c=fsdui.Controller(); cleanup=onCleanup(@()c.close()); c.run('DEMO',struct(),false);
            c.run('BUILD',struct('scope',"FRONT",'resultId',c.nextResultId()),false);
            % Deliberately sorts AFTER generated UI_RESULT IDs: lexical ID is not execution order.
            c.run('BUMP',struct('scope',"FL",'plan',struct('travel_m',[-.01;0;.01]),'resultId',"Z_BASE_BUMP"),false);
            fsd.project.saveEngineeringProject(c.Project,t.BaseFile,false);
            c.run('REFERENCE_TARGETS',struct(),false);
            c.run('SYNTHESIS',struct('scenarioId',"UI_SEARCH_FL",'resultId',c.nextResultId()),false);
            fsd.project.saveEngineeringProject(c.Project,t.SearchFile,false);
            copyfile(t.BaseFile,fullfile(root,'output','v018-fix-base.mat'));
            copyfile(t.SearchFile,fullfile(root,'output','v018-fix-search.mat'));
        end
    end
    methods (TestMethodSetup)
        function freshApp(t)
            t.App=FSSuspensionDesigner(); t.View=t.App.UIFigure.UserData;
            t.View.UI.Async.Value=false; t.addTeardown(@()cleanup(t.View,t.App.UIFigure));
            t.View.invoke('LOAD',struct('file',t.BaseFile));
            t.choose(t.View.UI.AnalysisTab); t.choose(t.View.UI.AnalysisCorner,'FL'); drawnow;
        end
    end
    methods (Test)
        function closedViewReleasesOwnedDataAndCallbacks(t)
            c=t.View.Controller; original=c.Project;
            sample=t.View.UI.Sample;
            t.View.shutdown();
            t.verifyEmpty(sample.UserData,'A retained hidden figure must not retain its old raw BUMP record.');
            t.verifyEmpty(t.View.Controller);
            t.verifyEmpty(fieldnames(t.View.UI)); t.verifyEmpty(t.View.Figure);
            t.verifyEmpty(fieldnames(t.View.Packaging.UI));
            t.verifyEmpty(t.View.Packaging.Axes);
            t.verifyEqual(c.Project,original,'Release view ownership, never mutate external snapshots.');
            t.View.shutdown(); % Idempotent cleanup of a retained closed View.
        end
        function geometryEditHistoricalAndReanalysis(t,ChangedGroup)
            c=t.View.Controller; original=c.Project.definition.results;
            info=t.View.UI.StateEvidence.UserData;
            t.verifyTrue(info.applicable); t.verifyEqual(info.status,"CURRENT_EXECUTION");
            t.choose(t.View.UI.GeometryTab); t.choose(t.View.UI.Group,ChangedGroup);
            rows=t.View.UI.DecisionTable.Data; value=str2double(rows{1,2});
            % Explicit 5 mm perturbation of the existing software fixture, not a design tolerance.
            t.type(t.View.UI.DecisionTable,[1 2],char(compose('%.17g',value+.005)));
            buttons=findall(t.View.UI.GeometryTab,'Type','uibutton');
            t.press(buttons(string({buttons.Text})=="Apply decisions")); t.press(t.View.UI.Build);
            t.choose(t.View.UI.AnalysisTab); drawnow;
            verifyStale(t);
            saveVisual(t,"v018-fix-"+ChangedGroup+"-stale.mat");
            old=c.Project; profile clear; profile on;
            t.choose(t.View.UI.Metric,'toe_rad'); drawnow;
            profile off; profiling=profile('info'); names=string({profiling.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["solveBump","fsolve","runEngineeringScenario","boundedDirectSearch"])));
            t.verifyEqual(c.Project,old);
            for j=1:numel(original)
                match=cellfun(@(r)r.id==original{j}.id,c.Project.definition.results);
                t.verifyEqual(c.Project.definition.results{match},original{j});
            end
            t.type(t.View.UI.Travel,'-0.01 0 0.01'); t.press(t.View.UI.RunBump); drawnow;
            t.verifyEmpty(c.LastError); fresh=t.View.UI.StateEvidence.UserData;
            t.verifyTrue(fresh.applicable); t.verifyEqual(fresh.status,"CURRENT_EXECUTION");
            t.verifyNotEqual(fresh.resultId,info.resultId);
            allEvidence=t.View.UI.CurveEvidence.UserData;
            t.verifyTrue(any(cellfun(@(e)e.status=="STALE",allEvidence)));
            t.verifyTrue(any(cellfun(@(e)e.resultId==fresh.resultId && e.applicable,allEvidence)));
            t.verifyTrue(any(contains(string(t.View.UI.StateAxes.Title.String),'CURRENT_EXECUTION')));
            t.verifyGreaterThan(t.View.UI.StateAxes.Position(4),130,'Warnings must not collapse the pose viewport at the default desktop size.');
            t.verifyTrue(contains(string(t.View.CurveAxes.Title.String),'Mixed'));
            saveVisual(t,"v018-fix-"+ChangedGroup+"-current.mat");
        end
        function independentChangesRemainReusable(t)
            c=t.View.Controller; original=c.Project;
            definition=original.definition.concept.definitionSI;
            rows=fsdui.parameterRows(fsd.project.conceptParameterCatalog(),definition.parameters,true);
            k=string(rows(:,1))=="VEHICLE_MASS"; rows{k,2}='201';
            definition.parameters=fsdui.parametersFromRows(rows,definition.parameters,"",true);
            c.run('VEHICLE',struct('definition',definition),false); drawnow;
            info=t.View.UI.StateEvidence.UserData;
            t.verifyEqual(info.status,"REUSABLE_DEPENDENCIES"); t.verifyTrue(info.applicable);
            revised=fsd.project.reviseEngineeringProject(c.Project,struct('description',"Independent display note"));
            file=string(fullfile(t.Folder,'independent.mat')); fsd.project.saveEngineeringProject(revised,file,false);
            t.View.invoke('LOAD',struct('file',file)); drawnow;
            t.verifyEqual(t.View.UI.StateEvidence.UserData.status,"REUSABLE_DEPENDENCIES");
            t.verifyFalse(any(contains(string(t.View.UI.CurveEvidence.Value),'STALE')));
            t.verifyEqual(c.Project.definition.results,original.definition.results);
        end
        function adoptionAndMatKeepHistoricalWarnings(t)
            t.View.invoke('LOAD',struct('file',t.SearchFile)); c=t.View.Controller;
            results=c.Project.definition.results; selected=results{cellfun(@(r)r.engine=="CORNER_SYNTHESIS",results)};
            c.run('ADOPT',struct('resultId',selected.id,'index',selected.nativePayload.selectedIndex),false); drawnow;
            verifyStale(t); t.verifyEqual(c.Project.definition.results,results);
            file=string(fullfile(t.Folder,'adopted.mat')); c.run('SAVE',struct('file',file,'overwrite',false),false);
            historical=c.Project;
            t.View.invoke('NEW',struct('id',"OTHER_PROJECT")); drawnow;
            t.verifyEmpty(t.View.UI.CurveEvidence.UserData); t.verifyEmpty(t.View.UI.StateEvidence.UserData);
            t.verifyEmpty(t.View.UI.StateAxes.Children);
            t.View.invoke('LOAD',struct('file',file)); drawnow; verifyStale(t);
            t.verifyEqual(c.Project,historical);
            saveVisual(t,"v018-fix-adopted.mat");
            t.View.invoke('LOAD',struct('file',t.BaseFile)); drawnow;
            t.verifyTrue(t.View.UI.StateEvidence.UserData.applicable);
            t.verifyFalse(any(contains(string(t.View.UI.CurveEvidence.Value),'STALE')));
        end
        function conflictingJsonApplyIsAtomic(t)
            c=t.View.Controller; before=c.Project; reports=c.Compatibility; action=c.LastAction;
            t.choose(t.View.UI.VehicleTab);
            rows=t.View.UI.VehicleTable.Data; k=find(string(rows(:,1))=="WHEELBASE");
            t.type(t.View.UI.VehicleTable,[1 2],'201'); % Valid earlier row must not leak into the project.
            t.type(t.View.UI.VehicleTable,[k 2],'1.61');
            t.type(t.View.UI.VehicleTable,[k 11],'{"value":2.2}');
            buttons=findall(t.View.UI.VehicleTab,'Type','uibutton');
            t.press(buttons(string({buttons.Text})=="Apply vehicle")); drawnow;
            t.verifyEqual(c.Project,before); t.verifyEqual(c.Compatibility,reports); t.verifyEqual(c.LastAction,action);
            t.verifyTrue(contains(string(t.View.UI.Status.Text),'WHEELBASE'));
            t.verifyTrue(contains(string(t.View.UI.Status.Text),'value'));
            t.verifyTrue(contains(string(t.View.UI.Status.Text),'fsd:ui:ExtraJSON'));
        end
    end
end
function verifyStale(t)
c=t.View.Controller; info=t.View.UI.StateEvidence.UserData;
t.verifyEqual(info.status,"STALE"); t.verifyFalse(info.applicable);
t.verifyTrue(any(contains(string(t.View.UI.CurveEvidence.Value),'STALE')));
t.verifyTrue(any(contains(string(t.View.UI.StateEvidence.Value),'HISTORICAL ONLY')));
t.verifyTrue(any(contains(string(t.View.UI.StateAxes.Title.String),'STALE')));
t.verifyEqual(info.currentRevision,c.Project.definition.revision);
t.verifyEqual(info.sourceId,"UI_BUMP_FL"); t.verifyEqual(info.cornerId,"FL");
t.verifyTrue(info.executedRevision<info.currentRevision);
t.verifyTrue(all(cell2mat(t.View.UI.AnalysisTable.Data(:,5))),'Original CONVERGED is retained separately.');
end
function cleanup(view,fig)
view.shutdown(); if isgraphics(fig), delete(fig); end
end
function saveVisual(t,name)
root=fileparts(fileparts(mfilename('fullpath')));
file=fullfile(root,'output',name);
fsd.project.saveEngineeringProject(t.View.Controller.Project,file,true);
end
