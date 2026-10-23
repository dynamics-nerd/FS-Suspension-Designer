classdef TestGuidedGlobalStaticUI < matlab.uitest.TestCase
    methods(TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
        end
    end
    methods(Test)
        function actualConfigurationRunHistoryAndComparison(t)
            [p,d]=globalStaticGuidedInputs; [v,c,fig]=open(t,p); t.choose(v.UI.GlobalStaticTab);
            u=v.GlobalStatic.UI; rows=fsdui.globalStaticConfiguration('ROWS',fsd.project.createEngineeringScenario(d));
            for name=string(fieldnames(rows))', u.(name).Data=rows.(name); end
            % Real edit/Apply gestures on native controls; no illustrative UI loader.
            t.type(u.tires,[1,5],'Explicit software benchmark, entered by test');
            t.press(u.Apply); drawnow; t.assertEmpty(c.LastError); t.verifyEqual(c.LastValue.status,"READY");
            t.press(u.Run); drawnow; t.assertEmpty(c.LastError); r=c.LastValue;
            t.verifyEqual(r.engine,"GLOBAL_STATIC");
            t.choose(u.Pages,'Results'); drawnow;
            t.verifySize(u.Corners.Data,[4,17]); t.verifySize(u.Attempts.Data,[1,5]);
            t.verifyEqual(cell2mat(u.Corners.Data(:,11)),r.nativePayload.equilibrium.alternatives{1}.state.normalForces_N);
            t.verifySize(u.Comparison.Data,[4,4]);
            t.verifySize(u.PoseComparison.Data,[15,5]);
            t.choose(u.Alternative,'NONE'); drawnow; t.verifyEmpty(u.Corners.Data); t.verifyEmpty(u.Comparison.Data);
            t.choose(u.Alternative,'1'); drawnow; t.verifySize(u.Corners.Data,[4,17]);
            % Equal normal loads with a shifted ground do not imply equal pose.
            firstId=char(r.id); t.choose(u.Pages,'Configuration');
            t.type(u.controls,[10,2],'1'); t.verifyEqual(string(u.Run.Enable),"off");
            t.press(u.Apply); t.press(u.Run); drawnow; t.assertEmpty(c.LastError);
            second=c.LastValue; t.choose(u.Pages,'Results'); t.choose(u.Primary,char(second.id));
            t.choose(u.Reference,firstId); drawnow;
            t.verifyTrue(any(contains(string(u.Summary.Value),'STALE')));
            t.verifyEqual(u.PoseComparison.Data{1,4},1,'AbsTol',1e-4); % heave change [mm]
            root=fileparts(fileparts(mfilename('fullpath'))); exportapp(fig,fullfile(root,'work','v021','ui-global-results.png'));
            t.choose(u.Pages,'Configuration'); exportapp(fig,fullfile(root,'work','v021','ui-global-configuration.png'));
            t.verifyEqual(string(v.UI.Scope.Items),["FRONT","FL","FR","RL","RR"]);
        end
        function blankInputsDoNotInventVehicleOrTires(t)
            p=fsd.project.createEngineeringProject(struct('concept',fsd.project.createVehicleConcept(struct('id',"EMPTY_GLOBAL"))));
            [v,c,~]=open(t,p); t.choose(v.UI.GlobalStaticTab); u=v.GlobalStatic.UI; before=c.Project;
            t.verifyTrue(all(cellfun(@isempty,u.tires.Data(:,2:5)),'all'));
            t.verifyTrue(all(contains(string(u.Resources.Data(:,2:4)),'MISSING'),'all'));
            t.press(u.Apply); drawnow; t.verifyEqual(c.Project,before);
            t.verifyTrue(any(contains(string(u.Status.Value),'finite numeric')));
        end
        function matRestoresConfigurationAndStoredEvidence(t)
            [p,d]=globalStaticGuidedInputs; d.id="CUSTOM_GLOBAL";
            s=fsd.project.createEngineeringScenario(d); p=fsdui.upsertScenario(p,s);
            [r,p]=fsd.project.runEngineeringScenario(p,d.id,'RESTORED_GLOBAL');
            [v,c,~]=open(t,p); t.choose(v.UI.GlobalStaticTab); u=v.GlobalStatic.UI;
            t.verifyEqual(string(u.Scenario.Value),"CUSTOM_GLOBAL");
            t.verifyEqual(u.paths.Data{4,2},char(join(compose('%.17g',d.plan.cornerPlans.RR.travel_m*1000),' ')));
            t.choose(u.Pages,'Results'); t.verifySize(u.Corners.Data,[4,17]);
            t.verifyEqual(cell2mat(u.Corners.Data(:,11)),r.nativePayload.equilibrium.alternatives{1}.state.normalForces_N);
            t.verifyEmpty(c.LastError);
        end
    end
end
function [v,c,fig]=open(t,p)
fig=uifigure('Visible','on'); v=fsdui.View(fig); c=v.Controller;
t.addTeardown(@()closeView(v,fig));
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); f=fullfile(folder.Folder,'input.mat');
fsd.project.saveEngineeringProject(p,f,false); c.run('LOAD',struct('file',f),false); v.UI.Async.Value=false; drawnow;
end
function closeView(v,fig)
if isvalid(v), v.shutdown(); end
if isgraphics(fig), delete(fig); end
end
