classdef TestTireUI < matlab.uitest.TestCase
    methods(TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
        end
    end
    methods(Test)
        function incompleteDefinitionAndMatRemainEditable(t)
            [view,c]=open(t); t.choose(view.UI.TiresTab); u=view.Tires.UI;
            t.verifyTrue(all(cellfun(@isempty,u.Parameters.Data(:,2))));
            t.type(u.Id,'PENDING_UI_TIRE'); t.press(u.Apply); drawnow;
            t.assertEmpty(c.LastError); t.verifyEqual(numel(c.Project.definition.resources.tires),1);
            t.verifyEmpty(c.Project.definition.resources.tires{1}.definition.force.parameters.mu0);
            t.verifyEqual(string(u.Run.Enable),"off");
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); file=fullfile(folder.Folder,'partial.mat');
            before=c.Project; view.invoke('SAVE',struct('file',file,'overwrite',false));
            view.invoke('LOAD',struct('file',file)); drawnow; t.assertEmpty(c.LastError);
            t.verifyEqual(c.Project,before); t.choose(u.Resource,'PENDING_UI_TIRE@1');
            t.verifyTrue(all(cellfun(@isempty,u.Parameters.Data(:,2))));
        end
        function nativeEditsStudyAssignmentsHistoryAndMat(t)
            [view,c,fig]=open(t); t.choose(view.UI.TiresTab); u=view.Tires.UI;
            t.press(u.Example); t.press(u.Apply); drawnow; t.assertEmpty(c.LastError);
            t.verifyEqual(string(u.Resource.Value),"SYNTHETIC_TIRE@1");
            t.choose(u.Page,'Study');
            for k=1:4, t.type(u.Assignments,[k,2],'SYNTHETIC_TIRE@1'); end
            t.press(u.ApplyAssignments); drawnow; t.assertEmpty(c.LastError);
            t.verifyEqual(numel(c.Project.definition.resources.tireAssignments),4);
            t.type(u.States,[1,2],'500'); t.type(u.States,[2,2],'-5 0 5');
            t.type(u.States,[3,2],'0'); t.type(u.States,[4,2],'0');
            t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError);
            t.verifyEqual(c.LastValue.status,"READY"); t.verifyEqual(string(u.Run.Enable),"on");
            t.press(u.Run); drawnow; t.assertEmpty(c.LastError); record=c.LastValue;
            t.choose(u.Page,'Results'); drawnow;
            t.verifySize(u.Values.Data,[3,9]); t.verifyEqual(cell2mat(u.Values.Data(:,6)),record.nativePayload.Fy_N);
            t.verifyTrue(any(contains(string(u.Summary.Value),'MODEL CURVE')));
            t.verifyTrue(any(contains(string(u.Summary.Value),'assumptions true')));
            t.verifyTrue(all(contains(string(u.Values.Data(:,7:8)),'ASSUMPTION_BASED'),'all'));
            t.verifyGreaterThanOrEqual(numel(u.Axes.Children),2);
            t.choose(u.Primary,'NONE');
            t.choose(u.Primary,char(record.id));
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); file=fullfile(folder.Folder,'complete.mat');
            before=c.Project; view.invoke('SAVE',struct('file',file,'overwrite',false));
            view.invoke('LOAD',struct('file',file)); drawnow; t.assertEmpty(c.LastError);
            t.verifyEqual(c.Project,before); t.verifyEqual(cell2mat(u.Values.Data(:,6)),record.nativePayload.Fy_N);
            exportapp(fig,fullfile(folder.Folder,'tires.png'));
            root=fileparts(fileparts(mfilename('fullpath')));
            if isfolder(fullfile(root,'work','v022')), exportapp(fig,fullfile(root,'work','v022','ui-tires.png')); end
        end
        function modelAndStudyDraftsAreNotLostByOtherApply(t)
            [view,c]=open(t); t.choose(view.UI.TiresTab); u=view.Tires.UI;
            t.press(u.Example); t.press(u.Apply); drawnow; t.assertEmpty(c.LastError);
            t.type(u.Name,'Edited definition draft');
            t.choose(u.Page,'Study'); t.type(u.States,[1,2],'700');
            t.choose(u.Page,'Definition'); t.press(u.Apply); drawnow; t.assertEmpty(c.LastError);
            t.verifyTrue(view.Tires.hasDraft()); t.verifyEqual(string(u.States.Data{1,2}),"700");
            t.verifyEqual(string(u.Run.Enable),"off");
            t.verifyEqual(numel(c.Project.definition.resources.tires),2);
        end
        function globalLibrarySourceAndMissingAssignmentAreVisible(t)
            [view,c,fig]=open(t); [p,d]=globalStaticGuidedInputs;
            td=tireCharacterizationInputs; [p,tire]=fsd.project.registerTire(p,td); ids=["FL","FR","RL","RR"]; aa=cell(4,1);
            for k=1:4, aa{k}=struct('cornerId',ids(k),'tireId',tire.definition.id,'tireRevision',1); end
            p=fsd.project.assignTires(p,aa); p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); file=fullfile(folder.Folder,'library.mat');
            fsd.project.saveEngineeringProject(p,file,false); view.invoke('LOAD',struct('file',file)); drawnow;
            t.assertEmpty(c.LastError); t.choose(view.UI.GlobalStaticTab); u=view.GlobalStatic.UI;
            t.choose(u.Source,'LIBRARY_ASSIGNMENTS'); t.verifyFalse(any(u.tires.ColumnEditable));
            t.press(u.Apply); drawnow; t.assertEmpty(c.LastError); t.verifyEqual(c.LastValue.status,"READY");
            t.verifyEqual(c.Project.definition.scenarios{1}.definition.inputs,struct('tireSource',"LIBRARY_ASSIGNMENTS"));
            t.verifyEqual(cell2mat(u.tires.Data(:,2:3)),repmat([100,250],4,1));
            t.press(u.Run); drawnow; t.assertEmpty(c.LastError);
            t.verifyEqual(c.LastValue.engine,"GLOBAL_STATIC");
            t.choose(u.Pages,'Results'); t.verifySize(u.Corners.Data,[4,17]);
            root=fileparts(fileparts(mfilename('fullpath')));
            if isfolder(fullfile(root,'work','v022')), exportapp(fig,fullfile(root,'work','v022','ui-library-global.png')); end
            t.choose(view.UI.TiresTab); a=view.Tires.UI; t.choose(a.Page,'Study');
            t.type(a.Assignments,[2,2],''); t.press(a.ApplyAssignments); drawnow; t.assertEmpty(c.LastError);
            t.choose(view.UI.GlobalStaticTab);
            t.verifyTrue(any(contains(string(u.Status.Value),'TIRE:FR:ASSIGN_LIBRARY_REVISION')));
            t.verifyEqual(string(u.Run.Enable),"off");
            t.choose(u.Pages,'Configuration'); t.choose(u.Source,'SCENARIO_TIRES');
            t.verifyTrue(all(u.tires.ColumnEditable(2:5)));
        end
        function compatibleHypothesesOverlayAndDifferentStatesDoNot(t)
            [view,c,fig]=open(t); [d,s,q]=tireCharacterizationInputs; s.alpha_rad=[-.1;0;.1];
            p=fsd.project.createEngineeringProject(struct('concept',fsd.project.createVehicleConcept(struct('id',"TIRE_COMPARISON"))));
            [p,a]=fsd.project.registerTire(p,d); d.force.parameters.mu0=1.2; [p,b]=fsd.project.registerTire(p,d);
            tires={a,b,b}; records=cell(3,1);
            for k=1:3
                states=s; if k==3, states.kappa=.1; end
                tire=tires{k}; id="COMPARE_"+k;
                scenario=fsd.project.createEngineeringScenario(struct('id',id,'engine',"TIRE_CHARACTERIZATION", ...
                    'scope',fsd.model.designScope('VEHICLE','VEHICLE'), ...
                    'inputs',struct('tireId',tire.definition.id,'tireRevision',tire.definition.revision), ...
                    'plan',struct('states',states,'request',q)));
                p=fsdui.upsertScenario(p,scenario); [records{k},p]=fsd.project.runEngineeringScenario(p,id,"CURVE_"+k);
            end
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); file=fullfile(folder.Folder,'compare.mat');
            fsd.project.saveEngineeringProject(p,file,false); view.invoke('LOAD',struct('file',file)); drawnow; t.assertEmpty(c.LastError);
            t.choose(view.UI.TiresTab); u=view.Tires.UI; t.choose(u.Page,'Results');
            t.choose(u.Primary,'CURVE_1'); t.choose(u.Reference,'CURVE_2'); drawnow;
            t.verifyNumElements(u.Axes.Children,4); t.verifyTrue(any(contains(string(u.Summary.Value),'Reference CURVE_2')));
            t.verifyNotEqual(records{1}.nativePayload.Fy_N,records{2}.nativePayload.Fy_N);
            t.verifyEqual(cell2mat(u.Values.Data(:,6)),records{1}.nativePayload.Fy_N);
            root=fileparts(fileparts(mfilename('fullpath')));
            if isfolder(fullfile(root,'work','v022')), exportapp(fig,fullfile(root,'work','v022','ui-comparison.png')); end
            t.choose(u.Reference,'CURVE_3'); drawnow; t.verifyNumElements(u.Axes.Children,2);
            t.verifyTrue(any(contains(string(u.Summary.Value),'conditions differ')));
        end
    end
end
function [view,c,fig]=open(t)
fig=uifigure('Visible','on'); view=fsdui.View(fig); c=view.Controller;
t.addTeardown(@()close(view,fig)); view.UI.Async.Value=false; drawnow;
end
function close(view,fig)
if isvalid(view), view.shutdown(); end
if isgraphics(fig), delete(fig); end
end
