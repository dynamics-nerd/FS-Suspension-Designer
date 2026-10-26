classdef TestAntiRollBarUI < matlab.uitest.TestCase
    methods(TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(root,fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
        end
    end
    methods(Test)
        function nativeAppShellOpensStoredClosureDiagnostics(t)
            p=globalStaticGuidedInputs; [p,b]=fsd.project.registerAntiRollBar(p,geometricAntiRollBarInputs(p,'FRONT','ROCKER'));
            d=struct('id',"SHELL_DIAGNOSTICS",'engine',"ARB_MECHANICAL",'scope',fsd.model.designScope('AXLE','FRONT'), ...
                'inputs',struct('arbId',b.definition.id,'arbRevision',1),'plan',struct('wheelTravel_m',[-.005,.005;0,0;.005,-.005], ...
                'driverTravel_m',{{(-.02:.004:.02)',(-.02:.004:.02)'}}));
            p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
            [r,p]=fsd.project.runEngineeringScenario(p,d.id,'SHELL_RESULT');
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); file=fullfile(folder.Folder,'shell.mat');
            fsd.project.saveEngineeringProject(p,file,false);
            app=launchFSSuspensionDesigner; fig=app.UIFigure; v=fig.UserData; t.addTeardown(@()finish(v,fig));
            v.UI.Async.Value=false; v.invoke('LOAD',struct('file',file)); drawnow; t.assertEmpty(v.Controller.LastError);
            t.choose(v.UI.ARBTab); u=v.Arb.UI; t.choose(u.Page,'Results'); drawnow;
            t.verifyEqual(string(u.Page.Value),"Results"); t.verifyEqual(v.Controller.Project,p);
            t.verifyTrue(any(contains(string(u.Summary.Value),'Constitutive port stiffness:')));
            % Public container scroll brings the actual numeric field into view.
            scroll(u.Results.Children,u.ModalSample.Parent); drawnow; t.type(u.ModalSample,2); drawnow;
            t.verifyTrue(any(contains(string(u.Details.Value),'Diagnostic sample 2')));
            t.verifyTrue(any(contains(string(u.Details.Value),'closure residual')));
            t.verifyEqual(r.nativePayload.study.responses{2}.closureEnds{1}.status,"AVAILABLE");
            scroll(u.Results.Children,'top'); drawnow; t.choose(u.Quantity,'TWIST'); drawnow;
            scroll(u.Results.Children,u.CurvePanel); drawnow; pause(.5); capture(fig,'ui-final-native-app.png');
            root=fileparts(fileparts(mfilename('fullpath'))); destination=fullfile(root,'work','v023');
            if isfolder(destination)
                exportgraphics(u.Axes,fullfile(destination,'ui-twist-curves.png'));
                scroll(u.Results.Children,u.GeometryPanel); drawnow; pause(.5);
                exportgraphics(u.GeometryAxes,fullfile(destination,'ui-geometry-axes.png'));
                scroll(u.Results.Children,'top'); drawnow; t.choose(u.Quantity,'TANGENT'); drawnow;
                scroll(u.Results.Children,u.CurvePanel); drawnow; pause(.5); exportgraphics(u.Axes,fullfile(destination,'ui-tangent-curves.png'));
            end
        end
        function partialDeclarationsAndCanonicalPlansRemainEditable(t)
            [v,c]=open(t); t.choose(v.UI.ARBTab); u=v.Arb.UI;
            t.verifyTrue(all(cellfun(@isempty,u.Parameters.Data(:,2))));
            t.type(u.Id,'PENDING_ARB'); t.choose(u.Axle,'FRONT'); t.press(u.Apply); drawnow; t.assertEmpty(c.LastError);
            t.choose(u.Page,'Study'); t.press(u.ApplyStudy); drawnow;
            t.assertEmpty(c.LastError); t.verifyEqual(c.LastValue.status,"MISSING_DATA");
            t.verifyEqual(string(u.Run.Enable),"off");
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); file=fullfile(folder.Folder,'partial.mat');
            before=c.Project; v.invoke('SAVE',struct('file',file,'overwrite',false)); v.invoke('LOAD',struct('file',file)); drawnow;
            t.assertEmpty(c.LastError); t.verifyEqual(c.Project,before);
            t.verifyTrue(all(cellfun(@isempty,u.Wheels.Data(:,2))));
            t.choose(u.Engine,'ARB_SIZING'); t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError);
            t.verifyEqual(c.LastValue.status,"UNSUPPORTED");
            t.choose(u.Page,'Definition'); t.choose(u.Representation,'COAXIAL_TORSION'); t.press(u.Apply); drawnow;
            t.assertEmpty(c.LastError); t.choose(u.Page,'Study'); t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError);
            t.verifyEqual(c.LastValue.status,"MISSING_DATA");
            before=c.Project; file=fullfile(folder.Folder,'partial-sizing.mat');
            v.invoke('SAVE',struct('file',file,'overwrite',false)); v.invoke('LOAD',struct('file',file)); drawnow;
            t.assertEmpty(c.LastError); t.verifyEqual(c.Project,before); t.verifyEqual(string(u.Run.Enable),"off");
            t.verifyTrue(all(cellfun(@isempty,u.Target.Data(:,2))));
        end
        function equivalentCurvesVariantsModalAndMat(t)
            [v,c,fig]=open(t); t.choose(v.UI.ARBTab); u=v.Arb.UI;
            t.choose(u.Axle,'FRONT'); t.press(u.Example); t.press(u.Apply); drawnow; t.assertEmpty(c.LastError);
            t.choose(u.Page,'Study'); t.type(u.Wheels,[1,2],'-10 0 10'); t.type(u.Wheels,[2,2],'10 0 -10');
            t.type(u.Assignments,[1,2],'SYNTHETIC_ARB@1'); t.press(u.ApplyAssignments); drawnow; t.assertEmpty(c.LastError);
            t.verifyTrue(v.Arb.hasDraft()); t.verifyEqual(string(u.Wheels.Data{1,2}),"-10 0 10");
            t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError); t.verifyEqual(c.LastValue.status,"READY");
            t.press(u.Run); drawnow; t.assertEmpty(c.LastError); first=c.LastValue;
            t.choose(u.Page,'Results'); t.verifySize(u.Values.Data,[3,14]);
            t.verifyEqual(cell2mat(u.Values.Data(:,9:10)),[-200,200;0,0;200,-200],'AbsTol',1e-12);
            t.verifyEqual(cell2mat(u.Values.Data(:,5)),[20;0;-20],'AbsTol',1e-12);
            t.choose(u.Quantity,'TANGENT'); t.verifyEqual(numel(u.Axes.Children),3);
            t.choose(u.LinearPath); t.type(u.ModalPath,[1,2],'1'); t.type(u.ModalPath,[1,3],'-1');
            t.type(u.ModalSample,3); t.type(u.ModalReference,2); t.type(u.ModalIncrement,'10'); t.press(u.ModalRun); drawnow;
            t.verifyTrue(any(contains(string(u.ModalOutput.Value),'Tangent: 40 N/mm')));
            t.verifyTrue(any(contains(string(u.ModalOutput.Value),'Incremental secant: 40 N/mm')));
            t.choose(u.Page,'Definition'); t.type(u.Adjustment,'STIFF_VARIANT');
            t.choose(u.Page,'Parameters');
            row=find(string(u.Parameters.Data(:,1))=="linearStiffness_N_per_m"); t.type(u.Parameters,[row,2],'20');
            t.press(u.ApplyParameters); drawnow; t.assertEmpty(c.LastError); t.verifyEqual(numel(c.Project.definition.resources.antiRollBars),2);
            t.choose(u.Page,'Study'); t.press(u.ApplyStudy); t.press(u.Run); drawnow; t.assertEmpty(c.LastError);
            t.verifyEqual(stored(c.Project,first.id),first);
            t.choose(u.Page,'Results'); t.choose(u.Reference,char(first.id)); t.choose(u.Quantity,'FORCES');
            t.verifyEqual(numel(u.Axes.Children),4);
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); file=fullfile(folder.Folder,'complete.mat');
            before=c.Project; v.invoke('SAVE',struct('file',file,'overwrite',false)); v.invoke('LOAD',struct('file',file)); drawnow;
            t.assertEmpty(c.LastError); t.verifyEqual(c.Project,before); capture(fig,'ui-equivalent.png');
        end
        function sizingUsesDeclaredSectionAndTarget(t)
            [v,c,fig]=open(t); t.choose(v.UI.ARBTab); u=v.Arb.UI;
            t.type(u.Id,'SHAFT_SIZE'); t.choose(u.Axle,'FRONT'); t.choose(u.Representation,'COAXIAL_TORSION'); t.choose(u.Section,'SOLID');
            t.choose(u.Page,'Parameters');
            for key=["G_Pa","effectiveLength_m"]
                row=find(string(u.Parameters.Data(:,1))==key); value='80'; if key=="effectiveLength_m", value='500'; end
                t.type(u.Parameters,[row,2],value);
                t.type(u.Parameters,[row,4],'ASSUMED');
                t.type(u.Parameters,[row,5],'Explicit sizing benchmark');
            end
            t.press(u.ApplyParameters); drawnow; t.assertEmpty(c.LastError); t.choose(u.Page,'Study'); t.choose(u.Engine,'ARB_SIZING');
            t.type(u.Target,[1,2],num2str(100*pi/180,17)); t.type(u.Target,[2,2],'KNOWN'); t.type(u.Target,[3,2],'User requested shaft stiffness');
            t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError); t.verifyEqual(c.LastValue.status,"READY");
            t.press(u.Run); drawnow; t.assertEmpty(c.LastError); t.choose(u.Page,'Results');
            t.verifySize(u.Values.Data,[1,5]); t.verifyEqual(u.Values.Data{1,1},1000*(32*.5*100/(pi*8e10))^.25,'RelTol',1e-13);
            capture(fig,'ui-sizing.png');
        end
        function nativeGeometryPackagingAndGlobalComparison(t)
            [v,c,fig]=open(t); [p,d]=globalStaticGuidedInputs;
            p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); file=fullfile(folder.Folder,'global.mat');
            fsd.project.saveEngineeringProject(p,file,false); v.invoke('LOAD',struct('file',file)); drawnow; t.assertEmpty(c.LastError);
            t.choose(v.UI.GlobalStaticTab); g=v.GlobalStatic.UI; t.press(g.Run); drawnow; t.assertEmpty(c.LastError); without=c.LastValue;
            t.choose(v.UI.ARBTab); u=v.Arb.UI; t.choose(u.Axle,'FRONT'); t.choose(u.Representation,'COAXIAL_TORSION');
            t.choose(u.LeftDriver,'ROCKER'); t.press(u.Example); t.press(u.Apply); drawnow; t.assertEmpty(c.LastError);
            bar=c.Project.definition.resources.antiRollBars{end};
            t.choose(u.Page,'Study'); t.type(u.Wheels,[1,2],'-10 0 10'); t.type(u.Wheels,[2,2],'10 0 -10');
            for side=1:2, t.type(u.DriverPaths,[side,2],'-20 -16 -12 -8 -4 0 4 8 12 16 20'); end
            t.type(u.Assignments,[1,2],char(bar.definition.id+"@1")); t.press(u.ApplyAssignments); drawnow; t.assertEmpty(c.LastError);
            t.choose(u.Page,'Packaging'); t.choose(u.PackEnabled); t.type(u.PackNote,'Synthetic occupied shaft versus remote sphere');
            t.type(u.Components,[1,5],'5'); t.type(u.Components,[1,6],'Explicit simplified shaft envelope');
            t.press(u.AddObstacle); values={'REMOTE','SPHERE','3000 0 0','100','','Synthetic remote sphere'};
            for j=[1:4,6], t.type(u.Obstacles,[1,j],values{j}); end
            t.press(u.AddPair); values={'SHAFT_REMOTE','SHAFT','REMOTE','10'};
            for j=1:4, t.type(u.Pairs,[1,j],values{j}); end
            t.choose(u.Page,'Study'); t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError); t.verifyEqual(c.LastValue.status,"READY");
            t.press(u.Run); drawnow; t.assertEmpty(c.LastError); t.verifyEqual(c.LastValue.nativePayload.packaging.status,"CLEAR_SAMPLED");
            t.choose(u.Page,'Results'); t.verifySize(u.PackResults.Data,[3,5]); t.verifyEqual(numel(u.GeometryAxes.Children),5);
            capture(fig,'ui-geometric.png');
            t.choose(v.UI.GlobalStaticTab); t.choose(g.ARBAxles,'FRONT'); t.press(g.Apply); drawnow; t.assertEmpty(c.LastError);
            t.press(g.Run); drawnow; t.assertEmpty(c.LastError); t.choose(g.Pages,'Results');
            t.choose(g.Primary,char(c.LastValue.id)); t.choose(g.Reference,char(without.id)); drawnow;
            t.verifySize(g.AntiRollBars.Data,[1,7]); t.verifySize(g.Comparison.Data,[4,4]);
            t.verifyEqual(stored(c.Project,without.id),without); capture(fig,'ui-global-arb.png');
        end
    end
end
function [v,c,fig]=open(t)
fig=uifigure('Visible','on'); v=fsdui.View(fig); t.addTeardown(@()finish(v,fig));
c=v.Controller; v.UI.Async.Value=false; drawnow;
end
function finish(v,fig)
if isvalid(v), v.shutdown(); end
if isgraphics(fig), delete(fig); end
end
function capture(fig,name)
root=fileparts(fileparts(mfilename('fullpath'))); folder=fullfile(root,'work','v023');
if isfolder(folder), exportapp(fig,fullfile(folder,name)); end
end
function r=stored(p,id)
records=p.definition.results; match=cellfun(@(r)r.id==id,records); r=records{match};
end
