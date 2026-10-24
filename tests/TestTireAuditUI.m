classdef TestTireAuditUI < matlab.uitest.TestCase
    properties(TestParameter)
        Case={"DEFAULT","REVERSED","INCOMPLETE"}
    end
    methods(TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
        end
    end
    methods(Test)
        function canonicalPlansOpenCompleteRunAndRecover(t,Case)
            [d,s,~]=tireCharacterizationInputs; s.alpha_rad=[-.01;0;.01];
            p=fsd.project.createEngineeringProject(struct('concept',fsd.project.createVehicleConcept(struct('id',"CANONICAL_UI"))));
            [p,tire]=fsd.project.registerTire(p,d);
            plan=struct('states',s,'request',struct());
            if Case=="REVERSED", plan.request=struct('channels',["Fy";"Fx"]); end
            if Case=="INCOMPLETE", plan=struct(); end
            scenario=fsd.project.createEngineeringScenario(struct('id',"CANONICAL_STUDY",'engine',"TIRE_CHARACTERIZATION", ...
                'scope',fsd.model.designScope('VEHICLE','VEHICLE'),'inputs',struct('tireId',tire.definition.id,'tireRevision',1),'plan',plan));
            p=fsdui.upsertScenario(p,scenario);
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); file=fullfile(folder.Folder,'canonical.mat');
            fsd.project.saveEngineeringProject(p,file,false);
            fig=uifigure('Visible','on'); view=fsdui.View(fig); t.addTeardown(@()finish(view,fig));
            c=view.Controller; view.UI.Async.Value=false; drawnow;
            view.invoke('LOAD',struct('file',file)); drawnow; t.assertEmpty(c.LastError);
            t.choose(view.UI.TiresTab); u=view.Tires.UI; t.choose(u.Page,'Study'); drawnow;
            t.verifyEqual(c.Project,p); t.verifyEqual(c.Project.definition.scenarios{1}.definition.plan,plan);
            if Case=="INCOMPLETE"
                t.verifyTrue(all(cellfun(@isempty,u.States.Data(:,2))));
                t.verifyEqual(string(u.Run.Enable),"off");
                t.verifyTrue(any(contains(string(u.Status.Value),'MISSING_DATA')));
                t.type(u.States,[1,2],'500'); t.type(u.States,[2,2],'-1 0 1');
                t.type(u.States,[3,2],'0'); t.type(u.States,[4,2],'0');
            elseif Case=="REVERSED"
                t.verifyEqual(string(u.Channels.Value),"Fy+Fx");
            else
                t.verifyEqual(string(u.Channels.Value),"Fx+Fy"); t.verifyEqual(string(u.Policy.Value),"MARK");
            end
            if Case~="INCOMPLETE", t.verifyEqual(string(u.Run.Enable),"on"); end
            % A direct READY run preserves the originally loaded declaration.
            if Case~="INCOMPLETE"
                t.press(u.Run); drawnow; t.assertEmpty(c.LastError);
                t.verifyEqual(c.Project.definition.scenarios{1}.definition.plan,plan);
            end
            t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError);
            t.verifyEqual(c.LastValue.status,"READY"); t.verifyEqual(string(u.Run.Enable),"on");
            expected=["Fx";"Fy"]; if Case=="REVERSED", expected=["Fy";"Fx"]; end
            t.verifyEqual(c.Project.definition.scenarios{1}.definition.plan.request.channels,expected);
            t.press(u.Run); drawnow; t.assertEmpty(c.LastError);
            t.verifyEqual(c.LastValue.nativePayload.request.channels,expected);
            t.choose(u.Page,'Results'); drawnow; t.verifySize(u.Values.Data,[3,9]);
            before=c.Project; saved=fullfile(folder.Folder,'completed.mat');
            view.invoke('SAVE',struct('file',saved,'overwrite',false)); view.invoke('LOAD',struct('file',saved)); drawnow;
            t.assertEmpty(c.LastError); t.verifyEqual(c.Project,before);
            t.choose(u.Page,'Study'); t.verifyEqual(split(string(u.Channels.Value),'+'),expected);
            root=fileparts(fileparts(mfilename('fullpath'))); evidence=fullfile(root,'work','v022-audit-fixes');
            if isfolder(evidence), exportapp(fig,fullfile(evidence,"ui-"+lower(Case)+".png")); end
        end
    end
end
function finish(view,fig)
if isvalid(view), view.shutdown(); end
if isgraphics(fig), delete(fig); end
end
