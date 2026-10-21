classdef TestPackagingSelectionUI < matlab.uitest.TestCase
    % V19-F-01: actual native table gestures, never direct callback invocation.
    properties
        Project
    end
    methods (TestClassSetup)
        function nativeEvidence(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'),fullfile(root,'app'));
            [definition,g]=packagingMotionFixture(.08);
            scenario=fsd.project.createEngineeringScenario(struct('id',"BUMP_SOURCE",'engine',"BUMP", ...
                'scope',fsd.model.designScope('CORNER','FL'),'plan',struct('travel_m',[0;.04;.08])));
            concept=fsd.project.createVehicleConcept(struct('id',"SELECTION_TEST"));
            p=fsd.project.createEngineeringProject(struct('concept',concept, ...
                'resources',struct('geometries',{{g}},'packaging',{{definition}}),'scenarios',{{scenario}}));
            bump=fsd.project.runEngineeringScenario(p,"BUMP_SOURCE","BUMP_EVIDENCE");
            p=fsd.project.attachEngineeringResult(p,bump);
            s=fsd.project.createPackagingScenario('PACK','FL','SOFTWARE_CASE', ...
                struct('mode',"BUMP",'requested_m',[0;.04;.08]),bump,'REGISTRY',[]);
            p=fsd.project.reviseEngineeringProject(p,struct('scenarios',{{scenario;s}}));
            for id=["PACK_A","PACK_B"]
                r=fsd.project.runEngineeringScenario(p,"PACK",id); p=fsd.project.attachEngineeringResult(p,r);
            end
            t.Project=p;
        end
    end
    methods (Test)
        function sameCellAfterFilterKeepsPoseAndWitnessesConsistent(t)
            [v,c,fig]=openView(t); ui=v.UI;
            t.choose(ui.ResultPicker,'PACK_A');
            for column=[3 1 2 4]
                t.choose(ui.Filter,'ALL'); t.choose(ui.Checks,[1 column]); drawnow;
                t.verifyEqual(v.Axes.UserData.sampleIndex,1);
                t.verifyEqual(v.Axes.UserData.pairStatus,"CLEAR_SAMPLED");
                t.verifyGreaterThan(numel(findobj(v.Axes,'Type','line','Color',[0 0 0])),0);
                t.choose(ui.Filter,'ISSUES'); t.choose(ui.Checks,[1 column]); drawnow;
                t.verifyEqual(ui.Checks.Data{1,1},3);
                t.verifyEqual(v.Axes.UserData.sampleIndex,3);
                t.verifyEqual(v.Axes.UserData.pairStatus,"COLLISION_DETECTED");
                t.verifyEqual(ui.Status.UserData.selection.resultId,"PACK_A");
                t.verifyEqual(ui.Status.UserData.selection.sampleIndex,3);
                t.verifyEmpty(findobj(v.Axes,'Type','line','Color',[0 0 0]));
                solids=findobj(v.Axes,'Type','surface'); t.assertNumElements(solids,2);
                for solid=solids', t.verifyEqual(solid.FaceColor,[.85 .22 .12]); end
            end
            t.choose(ui.Sample,'1'); drawnow;
            t.verifyEmpty(ui.Checks.Selection); t.verifyEqual(v.Axes.UserData.sampleIndex,1);
            t.verifyTrue(isnan(v.Axes.UserData.checkIndex));
            t.choose(ui.Filter,'CLEAR'); t.choose(ui.Checks,[2 3]); drawnow;
            t.verifyEqual(v.Axes.UserData.sampleIndex,2);
            t.choose(ui.ResultPicker,'PACK_B'); drawnow;
            t.verifyEqual(ui.Status.UserData.selection.resultId,"PACK_B");
            t.verifyEqual(v.Axes.UserData.sampleIndex,ui.Checks.Data{ui.Checks.Selection(1),1});
            t.verifyFalse(c.Busy); t.verifyTrue(isgraphics(fig));
        end
        function matReplacementAndEmptyProjectClearOldSelection(t)
            [v,c,~]=openView(t); ui=v.UI;
            t.choose(ui.Filter,'ALL'); t.choose(ui.Checks,[1 3]);
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            file=string(fullfile(folder.Folder,'selection.mat'));
            c.run('SAVE',struct('file',file,'overwrite',false),false);
            c.run('NEW',struct('id',"EMPTY_SELECTION"),false); drawnow;
            t.verifyEmpty(ui.Checks.Selection); t.verifyEmpty(ui.Checks.Data);
            t.verifyEmpty(v.Axes.UserData); t.verifyEmpty(v.Axes.Children);
            c.run('LOAD',struct('file',file),false); drawnow;
            t.choose(ui.ResultPicker,'PACK_A'); t.choose(ui.Checks,[1 3]);
            t.verifyEqual(ui.Status.UserData.selection.projectId,"SELECTION_TEST");
            t.verifyEqual(v.Axes.UserData.sampleIndex,1);
            t.choose(ui.Filter,'ISSUES'); t.choose(ui.Checks,[1 3]);
            t.verifyEqual(v.Axes.UserData.sampleIndex,3);
        end
    end
    methods (Access=private)
        function [v,c,fig]=openView(t)
            c=fsdui.Controller(t.Project); fig=uifigure('Position',[60 60 1240 850]);
            t.addTeardown(@()closeView(c,fig)); tabs=uitabgroup(fig,'Position',[0 0 1240 850]); tab=uitab(tabs);
            v=fsdui.PackagingView(tab,c,@(~,~)[],@()[]); c.Changed=@()v.refresh(); v.refresh(); drawnow;
        end
    end
end
function closeView(c,fig)
c.Changed=[]; c.close(); if isgraphics(fig), delete(fig); end
end
