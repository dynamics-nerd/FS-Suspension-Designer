classdef TestArbSizingUnits < matlab.uitest.TestCase
    properties(TestParameter)
        numericClass={'int8','uint8','int16','uint16','int32','uint32','int64','uint64','single','double'}
    end
    methods(TestMethodSetup)
        function setup(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path; t.addTeardown(@()path(old));
            addpath(root,fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
        end
    end
    methods(Test)
        function loadApplyEditAndMat(t,numericClass)
            original=cast(100,numericClass); [p,d]=fixture(original);
            [v,c,u,folder,fig]=open(t,p); t.choose(v.UI.ARBTab); t.choose(u.Page,'Study'); drawnow;
            presented=str2double(u.Target.Data{1,2});
            t.assertEqual(presented,100*pi/180,'AbsTol',4*eps(100*pi/180));
            t.verifyEqual(presented/(pi/180),100,'AbsTol',4*eps(100));
            t.verifyEqual(c.Project,p); t.verifyEqual(string(u.Run.Enable),"on");
            t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError);
            actual=scenario(c.Project,d.id).definition.plan;
            t.verifyEqual(actual,d.plan); t.verifyClass(actual.target.stiffness_Nm_per_rad,numericClass);
            t.verifyEqual(c.LastValue.status,"READY"); t.press(u.Run); drawnow; t.assertEmpty(c.LastError);
            t.verifyEqual(c.LastValue.nativePayload.target,d.plan.target);
            t.verifyEqual(c.LastValue.nativePayload.sizing.outerDiameter_m,(32*.5*100/(pi*8e10))^.25,'RelTol',1e-14);
            before=c.Project; saved=fullfile(folder,'unchanged.mat');
            v.invoke('SAVE',struct('file',saved,'overwrite',false)); v.invoke('LOAD',struct('file',saved)); drawnow;
            t.assertEmpty(c.LastError); t.verifyEqual(c.Project,before);
            t.verifyClass(scenario(c.Project,d.id).definition.plan.target.stiffness_Nm_per_rad,numericClass);
            if strcmp(numericClass,'int32')
                root=fileparts(fileparts(mfilename('fullpath'))); dest=fullfile(root,'work','v023-f01');
                if isfolder(dest)&&~isfile(fullfile(dest,'integer-preserved.mat'))
                    fsd.project.saveEngineeringProject(c.Project,fullfile(dest,'integer-preserved.mat'),false);
                end
            end
            t.choose(u.Page,'Study'); t.type(u.Target,[1,2],sprintf('%.17g',125*pi/180));
            t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError);
            edited=scenario(c.Project,d.id).definition.plan.target;
            t.verifyEqual(edited.stiffness_Nm_per_rad,125,'AbsTol',4*eps(125));
            t.verifyEqual(edited.sourceKind,d.plan.target.sourceKind); t.verifyEqual(edited.sourceNote,d.plan.target.sourceNote);
            t.press(u.Run); drawnow; t.assertEmpty(c.LastError);
            t.verifyEqual(c.LastValue.nativePayload.sizing.target_Nm_per_rad,125,'AbsTol',4*eps(125));
            before=c.Project; saved=fullfile(folder,'edited.mat');
            v.invoke('SAVE',struct('file',saved,'overwrite',false)); v.invoke('LOAD',struct('file',saved)); drawnow;
            t.assertEmpty(c.LastError); t.verifyEqual(c.Project,before);
            if strcmp(numericClass,'int32')
                root=fileparts(fileparts(mfilename('fullpath'))); dest=fullfile(root,'work','v023-f01');
                if isfolder(dest)
                    if ~isfile(fullfile(dest,'integer-original.mat')), fsd.project.saveEngineeringProject(p,fullfile(dest,'integer-original.mat'),false); end
                    if ~isfile(fullfile(dest,'integer-edited.mat')), fsd.project.saveEngineeringProject(c.Project,fullfile(dest,'integer-edited.mat'),false); end
                    exportapp(fig,fullfile(dest,'desktop-edited.png'));
                end
            end
        end
        function provenanceOnlyEditPreservesNumericDeclaration(t)
            [p,d]=fixture(int32(100)); [v,c,u]=open(t,p); t.choose(v.UI.ARBTab); t.choose(u.Page,'Study');
            t.type(u.Target,[3,2],'Explicit revised provenance'); t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError);
            target=scenario(c.Project,d.id).definition.plan.target;
            t.verifyEqual(target.stiffness_Nm_per_rad,int32(100)); t.verifyClass(target.stiffness_Nm_per_rad,'int32');
            t.verifyEqual(target.sourceNote,"Explicit revised provenance");
        end
        function analogousPlanControlsPromoteBeforeArithmetic(t)
            for motion=["PRESCRIBED","ROLL"]
                [p,d]=fixture([]); d.engine="ARB_KINEMATICS";
                d.plan=struct('motion',motion,'driverTravel_m',{{int8([-1;0;1]),int8([-1;0;1])}});
                if motion=="PRESCRIBED", d.plan.wheelTravel_m=int8([1,-1;0,0]);
                else, d.plan.rollAngles_rad=int8([-1;0;1]); d.plan.axleHeave_m=int8(1); end
                p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
                [v,c,u]=open(t,p); t.choose(v.UI.ARBTab); t.choose(u.Page,'Study');
                t.verifyEqual(fsdui.numberList(u.DriverPaths.Data{1,2}),[-1000;0;1000]);
                if motion=="PRESCRIBED", t.verifyEqual(fsdui.numberList(u.Wheels.Data{1,2}),[1000;0]);
                else
                    t.verifyEqual(fsdui.numberList(u.Roll.Data{1,2}),[-1;0;1]*180/pi,'AbsTol',4*eps(180/pi));
                    t.verifyEqual(fsdui.numberList(u.Roll.Data{2,2}),1000);
                end
                t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError);
                current=scenario(c.Project,d.id).definition.plan;
                t.verifyEqual(double(current.driverTravel_m{1}),double(d.plan.driverTravel_m{1}));
                if motion=="PRESCRIBED", t.verifyEqual(double(current.wheelTravel_m),double(d.plan.wheelTravel_m));
                else
                    t.verifyEqual(double(current.rollAngles_rad),double(d.plan.rollAngles_rad),'AbsTol',4*eps(1));
                    t.verifyEqual(double(current.axleHeave_m),double(d.plan.axleHeave_m));
                end
            end
        end
        function incompletePlansRemainExactAndEditable(t)
            for mode=1:3
                [p,d]=fixture([]); d.plan=struct();
                if mode==2, d.plan.target=struct(); elseif mode==3, d.plan.target=struct('stiffness_Nm_per_rad',[]); end
                p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
                [v,c,u,folder]=open(t,p); t.choose(v.UI.ARBTab); t.choose(u.Page,'Study');
                t.verifyTrue(all(cellfun(@isempty,u.Target.Data(:,2)))); t.verifyEqual(string(u.Run.Enable),"off");
                t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError); t.verifyEqual(c.LastValue.status,"MISSING_DATA");
                t.verifyEqual(scenario(c.Project,d.id).definition.plan,d.plan);
                before=c.Project; file=fullfile(folder,'partial.mat'); v.invoke('SAVE',struct('file',file,'overwrite',false));
                v.invoke('LOAD',struct('file',file)); drawnow; t.assertEmpty(c.LastError); t.verifyEqual(c.Project,before);
                t.type(u.Target,[1,2],sprintf('%.17g',100*pi/180)); t.type(u.Target,[2,2],'KNOWN'); t.type(u.Target,[3,2],'Completed explicit target');
                t.press(u.ApplyStudy); drawnow; t.assertEmpty(c.LastError); t.verifyEqual(c.LastValue.status,"READY");
            end
        end
    end
end
function [p,d]=fixture(value)
p=fsd.project.createEngineeringProject(struct('concept',fsd.project.createVehicleConcept(struct('id',"F01_TARGET"))));
source=struct('sourceKind',"ASSUMED",'sourceNote',"Independent scalar sizing benchmark");
b=struct('id',"F01_SHAFT",'axleId',"FRONT",'representation',"COAXIAL_TORSION",'section',"SOLID", ...
    'parameters',struct('G_Pa',8e10,'effectiveLength_m',.5),'provenance',struct('G_Pa',source,'effectiveLength_m',source));
[p,b]=fsd.project.registerAntiRollBar(p,b);
target=struct('stiffness_Nm_per_rad',value,'sourceKind',"KNOWN",'sourceNote',"User-declared target; preserve numeric class and provenance");
d=struct('id',"F01_SIZING",'engine',"ARB_SIZING",'scope',fsd.model.designScope('AXLE','FRONT'), ...
    'inputs',struct('arbId',b.definition.id,'arbRevision',1),'plan',struct('target',target));
p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
end
function [v,c,u,folder,fig]=open(t,p)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); folder=f.Folder;
file=fullfile(folder,'input.mat'); fsd.project.saveEngineeringProject(p,file,false);
app=FSSuspensionDesigner; fig=app.UIFigure; v=fig.UserData; t.addTeardown(@()finish(v,fig));
c=v.Controller; v.UI.Async.Value=false; v.invoke('LOAD',struct('file',file)); drawnow; t.assertEmpty(c.LastError); u=v.Arb.UI;
end
function s=scenario(p,id)
ss=p.definition.scenarios; s=ss{cellfun(@(s)s.definition.id==id,ss)};
end
function finish(v,fig)
if isvalid(v), v.shutdown(); end
if isgraphics(fig), delete(fig); end
end
