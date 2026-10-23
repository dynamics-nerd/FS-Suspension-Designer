classdef TestGuidedActuationUI < matlab.uitest.TestCase
    methods(TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
            folder=fullfile(root,'work','v020'); if ~isfolder(folder), mkdir(folder); end
        end
    end
    methods(Test)
        function nativeControlsAnalysisSynthesisAndAdoption(t)
            [p,~,s,options]=guidedActuationFixture();
            [v,c,fig]=openView(t,p); t.choose(v.UI.ActuationTab); a=v.Actuation; ui=a.UI;
            t.choose(ui.Pages,'Configuration');
            chooseConfiguration(t,ui);
            [points,mechanics,compression,rebound]=fsdui.actuationRows(s.seedActuation,s.seedMechanical);
            ui.Points.Data=points; ui.Mechanics.Data=mechanics; ui.Compression.Data=compression; ui.Rebound.Data=rebound;
            ui.Mechanical.Value=true;
            drawnow;
            exportapp(fig,fullfile(fileparts(fileparts(mfilename('fullpath'))),'work','v020','ui-before-edit.png'));
            t.type(ui.Points,[6 2],char(string(points{6,2}))); t.press(ui.Apply); drawnow;
            t.assertEmpty(c.LastError); t.verifyFalse(a.hasDraft());
            t.verifyEqual(c.Project.definition.resources.actuations{1}.identity,s.seedActuation.identity);
            t.choose(ui.Pages,'Analysis'); t.type(ui.Travel,'-10 0 10'); t.type(ui.Velocity,'0');
            t.choose(ui.Engine,'MECHANICAL'); t.press(ui.Readiness); drawnow;
            t.assertEmpty(c.LastError); t.verifyEqual(c.LastValue.status,"READY");
            t.press(ui.Run); drawnow; t.assertEmpty(c.LastError); result=c.LastValue;
            t.choose(ui.Pages,'Evidence'); drawnow;
            t.verifySize(ui.Rows.Data,[3,14]); t.verifyNotEmpty(a.Axes.Children);
            t.verifyEqual(a.Axes.XLabel.String,'X [mm]');
            t.choose(ui.Metric,'Total wheel rate [N/mm]'); drawnow;
            t.verifyEqual(a.CurveAxes.Children(1).YData(:),result.nativePayload.analysis.wheelRateTotal_N_per_m/1000);
            before=c.Project; t.choose(v.UI.VehicleTab); t.choose(v.UI.ActuationTab); drawnow;
            t.verifyEqual(c.Project,before,'Stored redraw must not revise data or run physics.');
            d=struct('id',"UI_ACT_SEARCH_FL",'engine',"ACTUATION_SYNTHESIS", ...
                'scope',fsd.model.designScope('CORNER','FL'),'specification',s.specification,'plan',s.plan,'options',options);
            c.run('SPECIFICATION',struct('definition',d),false);
            t.choose(ui.Pages,'Synthesis'); t.press(ui.ApplySearch); drawnow; t.assertEmpty(c.LastError);
            t.press(ui.Search); drawnow; t.assertEmpty(c.LastError); search=c.LastValue;
            t.choose(ui.Pages,'Evidence'); drawnow;
            records=search.nativePayload.search.records;
            index=find(cellfun(@(e)e.eligible && ~isempty(e.changes),records),1); t.assertNotEmpty(index);
            ui.Candidate.Value=index; t.choose(ui.Metric,'Signed motion ratio [1]'); drawnow;
            t.verifySize(ui.Candidates.Data,[numel(records),6]); t.verifyNumElements(a.CurveAxes.Children,2);
            geometry=c.Project.definition.resources.geometries;
            c.run('ACTUATION_ADOPT',struct('resultId',search.id,'index',index),false); drawnow;
            t.verifyEqual(c.Project.definition.resources.geometries,geometry);
            t.verifyTrue(any(contains(string(ui.Diagnostics.Value),'STALE')));
            ui.Candidate.Value=numel(records)+1; t.choose(ui.Metric,'Damper compression [mm]'); drawnow;
            t.verifyEmpty(ui.Rows.Data); t.verifyEmpty(a.Axes.Children); t.verifyEmpty(a.CurveAxes.Children);
            t.verifyEqual(string(ui.Adopt.Enable),"off");
            t.verifyTrue(any(contains(string(ui.Diagnostics.Value),'InvalidSelection')));
            ui.Candidate.Value=index; t.choose(ui.Metric,'Signed motion ratio [1]'); drawnow;
            t.verifyNotEmpty(a.Axes.Children); t.verifyNotEmpty(a.CurveAxes.Children);
            t.verifyFalse(any(contains(string(ui.Status.Value),'InvalidSelection')));
            root=fileparts(fileparts(mfilename('fullpath')));
            file=fullfile(root,'work','v020','ui-evidence.png'); exportapp(fig,file);
        end
        function invalidDraftCannotSaveOrApply(t)
            [p,~,s]=guidedActuationFixture(); [v,c,~]=openView(t,p);
            t.choose(v.UI.ActuationTab); ui=v.Actuation.UI;
            t.choose(ui.Pages,'Configuration');
            t.verifyEqual(ui.Architecture.Value,'UNSELECTED'); t.verifyEqual(ui.Body.Value,'UNSELECTED');
            t.verifyEqual(ui.Mode.Value,'UNSELECTED'); t.verifyEqual(ui.Law.Value,'UNSELECTED');
            chooseConfiguration(t,ui);
            [rows,m,co,re]=fsdui.actuationRows(s.seedActuation,s.seedMechanical);
            ui.Points.Data=rows; ui.Mechanics.Data=m; ui.Compression.Data=co; ui.Rebound.Data=re;
            before=c.Project; rows{1,2}=''; ui.Points.Data=rows;
            drawnow;
            t.type(ui.Points,[1 7],'Explicit test source'); t.press(ui.Apply); drawnow;
            t.verifyEqual(c.Project,before); t.verifyTrue(v.Actuation.hasDraft());
            t.verifyTrue(any(contains(string(ui.Status.Value),'SUSPENSION_ATTACHMENT')));
            v.invoke('SAVE',struct('file',fullfile(tempdir,'must-not-save-v020.mat'),'overwrite',false));
            t.verifyEqual(c.Project,before); t.verifyTrue(contains(string(v.UI.Status.Text),'UnappliedDraft'));
        end
        function recoveredAnalysisPlanDoesNotRequireSynthesis(t)
            [p,args]=guidedActuationFixture();
            c=fsdui.Controller(p); cleanup=onCleanup(@()c.close());
            c.run('ACTUATION_CONFIG',args,false);
            plan=struct('travel_m',[-.01;0;.01],'wheelVelocity_m_per_s',[-.02;0;.03]);
            c.run('ACTUATION_RUN',struct('cornerId',"FL",'engine',"MECHANICAL", ...
                'plan',plan,'resultId',"RECOVER_MECHANICAL"),false);
            [v,owner,~]=openView(t,c.Project); t.choose(v.UI.ActuationTab); ui=v.Actuation.UI;
            t.verifyEqual(ui.Engine.Value,'MECHANICAL');
            t.verifyEqual(fsdui.numberList(ui.Travel.Value),1000*plan.travel_m);
            t.verifyEqual(fsdui.numberList(ui.Velocity.Value),1000*plan.wheelVelocity_m_per_s);
            t.verifyFalse(v.Actuation.hasDraft());
            t.verifyEqual(owner.Project,c.Project);
            t.choose(ui.Pages,'Evidence'); t.verifySize(ui.Rows.Data,[3 14]);
        end
    end
end
function [v,c,fig]=openView(t,p)
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
file=fullfile(folder.Folder,'registered-geometry.mat'); fsd.project.saveEngineeringProject(p,file,false);
app=FSSuspensionDesigner(); fig=app.UIFigure; v=fig.UserData; c=v.Controller;
t.addTeardown(@()closeView(v,fig)); v.UI.Async.Value=false; c.run('LOAD',struct('file',file),false);
end
function closeView(v,fig)
v.shutdown(); if isgraphics(fig), delete(fig); end
end
function chooseConfiguration(t,ui)
t.choose(ui.Architecture,'PUSHROD'); t.choose(ui.Body,'UPRIGHT');
t.choose(ui.Mode,'YZ_PLANE'); t.choose(ui.Law,'LINEAR_ASYMMETRIC');
end
