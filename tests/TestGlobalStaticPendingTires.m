classdef TestGlobalStaticPendingTires < matlab.uitest.TestCase
    % V21-F-01: incomplete native projects remain editable without tire defaults.
    methods(TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
        end
    end
    methods(Test)
        function everyPendingCornerAndAllPending(t)
            [p,d]=globalStaticGuidedInputs;
            complete=fsdui.globalStaticConfiguration('ROWS',fsd.project.createEngineeringScenario(d));
            ids=["FL","FR","RL","RR"];
            for missing={1,2,3,4,1:4}
                absent=missing{1}; partial=d; partial.inputs.tires(absent)={[]};
                scenario=fsd.project.createEngineeringScenario(partial);
                before=scenario; rows=fsdui.globalStaticConfiguration('ROWS',scenario);
                expected=complete; expected.tires(absent,2:5)={''};
                t.verifyEqual(rows,expected); t.verifyEqual(scenario,before);
                project=fsdui.upsertScenario(p,scenario);
                readiness=fsd.project.designReadiness(project,d.id);
                t.verifyEqual(readiness.status,"MISSING_DATA");
                t.verifyTrue(all(ismember("TIRE:"+ids(absent)+":CONFIGURE_VERTICAL_TIRE",readiness.missing)));
            end
        end
        function completeConfigurationPreservesExactDefinition(t)
            [~,d]=globalStaticGuidedInputs;
            % Apply has always made the native numerical defaults explicit.
            d.options=fsd.analysis.globalStaticSolverSettings(d.options);
            d.plan.vehicleOptions.contactPoints_m=[]; % Existing inactive-contact declaration.
            s=fsd.project.createEngineeringScenario(d);
            rows=fsdui.globalStaticConfiguration('ROWS',s);
            restored=fsdui.globalStaticConfiguration('DEFINITION',rows,s);
            t.verifyEqual(fsd.project.createEngineeringScenario(restored),s);
        end
        function failedRenderCanRetrySameProject(t)
            [p,d]=globalStaticGuidedInputs;
            p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
            fig=uifigure('Visible','on'); t.addTeardown(@()delete(fig));
            tabs=uitabgroup(fig); tab=uitab(tabs);
            controller=GlobalStaticRenderController(p);
            view=fsdui.GlobalStaticView(tab,controller,@(~,~)[],@()[]);
            controller.FailFinalStatus=true;
            t.verifyError(@()view.refresh(),'fsd:test:TransientRender');
            % Same immutable project, repaired presentation dependency. The
            % next refresh must rebuild rows rather than trust a failed draw.
            view.UI.tires.Data=cell(4,5);
            view.refresh();
            rows=fsdui.globalStaticConfiguration('ROWS',p.definition.scenarios{1});
            t.verifyEqual(view.UI.tires.Data,rows.tires);
        end
        function nativeMatOpenCompleteRunAndRestore(t)
            [p,d]=globalStaticGuidedInputs; original=d.inputs.tires;
            d.inputs.tires{2}=[];
            p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            file=fullfile(folder.Folder,'pending-FR.mat'); fsd.project.saveEngineeringProject(p,file,false);
            fig=uifigure('Visible','on'); view=fsdui.View(fig); c=view.Controller;
            t.addTeardown(@()closeView(view,fig)); view.UI.Async.Value=false;
            % Same action and dispatch as Open trusted MAT after file selection.
            view.invoke('LOAD',struct('file',file)); drawnow;
            t.assertEmpty(c.LastError); t.verifyEqual(c.Project,p);
            t.choose(view.UI.GlobalStaticTab); u=view.GlobalStatic.UI;
            expected=fsdui.globalStaticConfiguration('ROWS',p.definition.scenarios{1});
            t.verifyEqual(u.tires.Data,expected.tires);
            t.verifyTrue(all(cellfun(@isempty,u.tires.Data(2,2:5))));
            t.verifyTrue(any(contains(string(u.Status.Value),'TIRE:FR:CONFIGURE_VERTICAL_TIRE')));
            t.verifyEqual(string(u.Run.Enable),"off");
            t.verifyEqual(string(u.Apply.Enable),"on");
            % Actual native edit gestures supply every previously absent input.
            tire=original{2};
            t.type(u.tires,[2,2],char(string(tire.stiffness_N_per_m/1000)));
            t.type(u.tires,[2,3],char(string(tire.unloadedRadius_m*1000)));
            t.type(u.tires,[2,4],char(tire.sourceKind));
            t.type(u.tires,[2,5],char(tire.sourceNote));
            t.press(u.Apply); drawnow; t.assertEmpty(c.LastError);
            t.verifyEqual(c.LastValue.status,"READY");
            t.verifyEqual(string(u.Run.Enable),"on");
            scenario=c.Project.definition.scenarios{1};
            t.verifyEqual(scenario.definition.inputs.tires,original);
            full=d; full.inputs.tires=original;
            full.options=fsd.analysis.globalStaticSolverSettings(full.options);
            full.plan.vehicleOptions.contactPoints_m=[];
            t.verifyEqual(scenario,fsd.project.createEngineeringScenario(full));
            t.verifyEqual(c.Project.definition.resources,p.definition.resources);
            t.press(u.Run); drawnow; t.assertEmpty(c.LastError);
            t.assertEqual(c.LastValue.engine,"GLOBAL_STATIC");
            t.verifyTrue(isfinite(c.LastValue.nativePayload.equilibrium.selectedIndex));
            t.choose(u.Pages,'Results'); t.verifySize(u.Corners.Data,[4,17]);
            completed=c.Project; evidence=u.Corners.Data;
            file=fullfile(folder.Folder,'completed.mat');
            view.invoke('SAVE',struct('file',file,'overwrite',false)); drawnow; t.assertEmpty(c.LastError);
            view.invoke('LOAD',struct('file',file)); drawnow; t.assertEmpty(c.LastError);
            t.verifyEqual(c.Project,completed); t.verifyEqual(u.Corners.Data,evidence);
            t.verifyTrue(any(contains(string(u.Status.Value),'Global readiness: READY')));
        end
    end
end
function closeView(view,fig)
if isvalid(view), view.shutdown(); end
if isgraphics(fig), delete(fig); end
end
