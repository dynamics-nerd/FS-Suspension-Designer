classdef TestArbPlanPreservation < matlab.uitest.TestCase
    properties(TestParameter)
        editedField={'HEAVE','ROLL','DRIVER'}
    end
    properties
        Project
        Scenario
        Result
    end
    methods(TestClassSetup)
        function fixture(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path; t.addTeardown(@()path(old));
            addpath(root,fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
            p=fsd.project.loadEngineeringProject(fullfile(root,'output','v023-validation','guided-anti-roll-bar.mat'));
            bars=p.definition.resources.antiRollBars;
            b=bars{find(cellfun(@(b)b.definition.axleId=="FRONT"&&b.definition.representation=="COAXIAL_TORSION",bars),1)};
            a=single(.000141249); z=single((-.02:.004:.02)');
            d=struct('id',"F02_ROLL",'engine',"ARB_MECHANICAL",'scope',fsd.model.designScope('AXLE','FRONT'), ...
                'inputs',struct('arbId',b.definition.id,'arbRevision',b.definition.revision), ...
                'name',"Audit ROLL declaration",'description',"Single precision explicit inputs, no UI normalization", ...
                'options',struct('MaxRollStep_rad',.01), ...
                'plan',struct('motion',"ROLL",'rollAngles_rad',[-a;single(0);a], ...
                'axleHeave_m',single(.001234567),'driverTravel_m',{{z,z}}));
            p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
            % A second stored scenario ensures a no-op does not reorder the ledger.
            extra=d; extra.id="F02_OTHER"; p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(extra));
            % New test project from the audited geometry; explicit initial revision.
            definition=p.definition; definition.revision=12; definition.results={}; definition.derivations={};
            p=fsd.project.createEngineeringProject(definition);
            assert(p.definition.revision==12,'The audit reproduction must start at revision 12.');
            [r,p]=fsd.project.runEngineeringScenario(p,d.id,'F02_ORIGINAL');
            assert(all(cellfun(@(v)v.available,r.nativePayload.study.responses)));
            assert(fsd.project.resultCompatibility(r,p).status=="CURRENT_EXECUTION");
            t.Project=p; t.Scenario=d; t.Result=r;
            folder=fullfile(root,'work','v023-f02');
            if isfolder(folder)&&~isfile(fullfile(folder,'roll-original.mat'))
                fsd.project.saveEngineeringProject(p,fullfile(folder,'roll-original.mat'),false);
            end
        end
    end
    methods(Test)
        function auditRollNoEditIsExactlyCurrent(t)
            [v,c,u,fig]=open(t,t.Project,t.Scenario.id);
            t.verifyEqual(c.Project.definition.revision,12); t.verifyEqual(c.Project,t.Project);
            t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError);
            t.verifyEqual(c.LastValue.status,"READY"); t.verifyEqual(c.Project,t.Project);
            d=findScenario(c.Project,t.Scenario.id).definition;
            t.verifyEqual(d.plan,t.Scenario.plan); t.verifyClass(d.plan.rollAngles_rad,'single');
            t.verifyClass(d.plan.axleHeave_m,'single'); t.verifyClass(d.plan.driverTravel_m{1},'single');
            t.verifySize(d.plan.rollAngles_rad,[3,1]); t.verifySize(d.plan.driverTravel_m{1},[11,1]);
            t.verifyEqual(c.Project.definition.revision,12); t.verifyEqual(c.Project.definition.results,t.Project.definition.results);
            t.verifyEqual(fsd.project.resultCompatibility(t.Result,c.Project).status,"CURRENT_EXECUTION");
            roundtrip(t,v,c,'no-edit.mat');
            evidence(c.Project,'roll-preserved.mat');
            scroll(u.Study.Children,u.Roll); drawnow; capture(fig,'desktop-roll-preserved.png');
        end
        function selectivePhysicalEditInvalidatesOnlyConsumers(t,editedField)
            [v,c,u,fig]=open(t,t.Project,t.Scenario.id); before=t.Scenario.plan;
            switch editedField
                case 'HEAVE', t.type(u.Roll,[2,2],'2');
                case 'ROLL', t.type(u.Roll,[1,2],'-0.01 0 0.01');
                case 'DRIVER', t.type(u.DriverPaths,[1,2],'-20 -10 0 10 20');
            end
            t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError);
            actual=findScenario(c.Project,t.Scenario.id).definition;
            expected=before;
            switch editedField
                case 'HEAVE', expected.axleHeave_m=.002;
                case 'ROLL', expected.rollAngles_rad=[-.01;0;.01]*pi/180;
                case 'DRIVER', expected.driverTravel_m{1}=[-.02;-.01;0;.01;.02];
            end
            t.verifyEqual(actual.plan,expected); t.verifyEqual(actual.options,t.Scenario.options);
            t.verifyEqual(actual.name,t.Scenario.name); t.verifyEqual(actual.description,t.Scenario.description);
            t.verifyEqual(c.Project.definition.revision,13); t.verifyEqual(c.Project.definition.results,t.Project.definition.results);
            t.verifyEqual(fsd.project.resultCompatibility(t.Result,c.Project).status,"STALE");
            t.verifyEqual(c.LastValue.status,"READY"); roundtrip(t,v,c,'edited.mat');
            evidence(c.Project,"roll-edited-"+editedField+".mat");
            if strcmp(editedField,'HEAVE'), scroll(u.Study.Children,u.Roll); drawnow; capture(fig,'desktop-roll-edited.png'); end
        end
        function editThenRestoreExactPresentationIsNoOp(t)
            [~,c,u]=open(t,t.Project,t.Scenario.id); original=u.Roll.Data{2,2};
            t.type(u.Roll,[2,2],'2'); t.type(u.Roll,[2,2],original);
            t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError); t.verifyEqual(c.Project,t.Project);
            t.verifyEqual(fsd.project.resultCompatibility(t.Result,c.Project).status,"CURRENT_EXECUTION");
        end
        function incompleteAndHiddenFieldsStayExact(t)
            for mode=1:3
                p=t.Project; d=t.Scenario; d.id="F02_PARTIAL"; d.options=struct();
                if mode==1, d.plan=struct();
                elseif mode==2, d.plan=struct('motion',"ROLL",'axleHeave_m',single.empty(1,0));
                else
                    d.options=struct();
                    d.plan=struct('motion',"PRESCRIBED",'wheelTravel_m',single([0,0;.001,-.001]), ...
                        'rollAngles_rad',single([0,.001]),'axleHeave_m',single(.001), ...
                        'driverTravel_m',{{single([-.02,0,.02]),single([-.02;0;.02])}});
                end
                p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
                [v,c,u]=open(t,p,d.id); t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError);
                t.verifyEqual(c.Project,p); t.verifyEqual(findScenario(c.Project,d.id).definition.plan,d.plan);
                roundtrip(t,v,c,'partial.mat');
            end
        end
        function prescribedEquivalentSelectiveWheelEdit(t)
            p=t.Project; [p,b]=fsd.project.registerAntiRollBar(p,antiRollBarInputs);
            d=t.Scenario; d.id="F02_PRESCRIBED"; d.inputs=struct('arbId',b.definition.id,'arbRevision',b.definition.revision);
            d.options=struct('MaxContinuationStep_m',.004);
            d.plan=struct('wheelTravel_m',single([-.001,.001;0,0;.001,-.001]));
            p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
            [v,c,u]=open(t,p,d.id); t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError); t.verifyEqual(c.Project,p);
            t.type(u.Wheels,[1,2],'-2 0 2'); t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError);
            actual=findScenario(c.Project,d.id).definition;
            t.verifyEqual(actual.plan.wheelTravel_m(:,1),[-.002;0;.002]);
            t.verifyEqual(actual.plan.wheelTravel_m(:,2),double(d.plan.wheelTravel_m(:,2)));
            t.verifyFalse(isfield(actual.plan,'motion')); t.verifyEqual(actual.options,d.options);
            roundtrip(t,v,c,'prescribed.mat');
        end
        function packagingEditsRetainUnrepresentedDeclarations(t)
            p=t.Project; d=t.Scenario; d.id="F02_PACKAGING";
            b=fsd.project.findAntiRollBar(p,d.inputs.arbId,d.inputs.arbRevision);
            d.plan.packaging=antiRollBarPackagingInputs(b);
            p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
            [v,c,u]=open(t,p,d.id); t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError); t.verifyEqual(c.Project,p);
            t.choose(u.Page,'Packaging'); t.type(u.PackNote,'Explicit edited packaging note');
            t.choose(u.Page,'Study'); t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError);
            expected=d.plan.packaging.definition; expected.provenance="Explicit edited packaging note";
            t.verifyEqual(findScenario(c.Project,d.id).definition.plan.packaging,fsd.packaging.createAntiRollBarDefinition(expected));
            t.choose(u.Page,'Packaging'); t.type(u.Components,[1,5],'6');
            t.choose(u.Page,'Study'); t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError);
            expected.components{1}.radius_m=.006;
            t.verifyEqual(findScenario(c.Project,d.id).definition.plan.packaging,fsd.packaging.createAntiRollBarDefinition(expected));
            t.choose(u.Page,'Packaging'); t.type(u.Obstacles,[1,4],'110');
            t.choose(u.Page,'Study'); t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError);
            obstacle=expected.obstacles{1}.definitionSI; obstacle.dimensions=.11;
            expected.obstacles{1}=fsd.packaging.createVolume(obstacle,'m');
            actual=findScenario(c.Project,d.id).definition;
            t.verifyEqual(actual.plan.packaging,fsd.packaging.createAntiRollBarDefinition(expected));
            t.verifyEqual(rmfield(actual.plan,'packaging'),rmfield(d.plan,'packaging'));
            roundtrip(t,v,c,'packaging.mat');
        end
        function motionEditRetainsDormantFields(t)
            p=t.Project; d=t.Scenario; d.id="F02_MOTION"; d.options=struct();
            d.plan.wheelTravel_m=single([-.001,.001;0,0;.001,-.001]);
            p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
            [v,c,u]=open(t,p,d.id); t.choose(u.Motion,'PRESCRIBED'); t.press(u.ApplyStudy); drawnow;
            t.assertEmpty(c.LastError); expected=d.plan; expected.motion="PRESCRIBED";
            t.verifyEqual(findScenario(c.Project,d.id).definition.plan,expected);
            t.verifyEqual(c.Project.definition.revision,p.definition.revision+1);
            t.verifyEqual(c.LastValue.status,"READY"); roundtrip(t,v,c,'motion.mat');
        end
    end
end
function [v,c,u,fig]=open(t,p,id)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); file=fullfile(f.Folder,'input.mat');
fsd.project.saveEngineeringProject(p,file,false); app=FSSuspensionDesigner; fig=app.UIFigure;
v=fig.UserData; t.addTeardown(@()finish(v,fig)); c=v.Controller; v.UI.Async.Value=false;
v.invoke('LOAD',struct('file',file)); drawnow; t.assertEmpty(c.LastError);
t.choose(v.UI.ARBTab); u=v.Arb.UI; t.choose(u.Page,'Study'); t.choose(u.Scenario,char(id)); drawnow;
end
function s=findScenario(p,id)
ss=p.definition.scenarios; s=ss{cellfun(@(s)s.definition.id==id,ss)};
end
function roundtrip(t,v,c,name)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); before=c.Project; file=fullfile(f.Folder,name);
v.invoke('SAVE',struct('file',file,'overwrite',false)); v.invoke('LOAD',struct('file',file)); drawnow;
t.assertEmpty(c.LastError); t.verifyEqual(c.Project,before);
end
function evidence(p,name)
root=fileparts(fileparts(mfilename('fullpath'))); file=fullfile(root,'work','v023-f02',name);
if isfolder(fileparts(file))&&~isfile(file), fsd.project.saveEngineeringProject(p,file,false); end
end
function capture(fig,name)
root=fileparts(fileparts(mfilename('fullpath'))); folder=fullfile(root,'work','v023-f02');
if isfolder(folder), exportapp(fig,fullfile(folder,name)); end
end
function finish(v,fig)
if isvalid(v), v.shutdown(); end
if isgraphics(fig), delete(fig); end
end
