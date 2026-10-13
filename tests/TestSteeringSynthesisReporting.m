classdef TestSteeringSynthesisReporting < matlab.unittest.TestCase
    properties (TestParameter)
        Appearance={"dark","light"}
        Scenario={"SINGLE","HARD_FAIL","GAP","BUILDER_FAIL"}
    end
    methods (TestMethodSetup)
        function setup(t)
            old=path; visible=get(groot,'DefaultFigureVisible');
            t.addTeardown(@() path(old)); t.addTeardown(@() set(groot,'DefaultFigureVisible',visible));
            addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'src'));
            set(groot,'DefaultFigureVisible','off');
        end
    end
    methods (Test)
        function pngLegendsGapsAndNoHiddenSolve(t,Appearance,Scenario)
            r=reportFixture(Scenario); before=r; profile clear; profile on;
            figures=fsd.synthesis.plotSteeringSynthesisResult(r); profile off;
            t.addTeardown(@() close(figures));
            info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["fsolve","fzero","solveBump","solveRack","solveAxleRoll","solveCornerPath"])));
            t.verifyFalse(any(contains(names,'compareDesignCandidates')));
            folder=string(tempname); mkdir(folder); t.addTeardown(@() rmdir(folder,'s'));
            checkedBump=false; checkedAck=false;
            for j=1:numel(figures)
                legends=findall(figures(j),'Type','legend');
                for k=1:numel(legends), t.verifyEqual(legends(k).Location,'eastoutside'); end
                target=findobj(figures(j),'Type','line','DisplayName','Target');
                bump=contains(string(figures(j).Name),"FL_BUMP");
                ack=contains(string(figures(j).Name),"ACK_");
                chosen=j<=2 || j==numel(figures) || (bump && ~checkedBump) || (ack && ~checkedAck);
                if ~chosen, continue; end
                checkedBump=checkedBump || bump; checkedAck=checkedAck || ack;
                theme(figures(j),Appearance); filename=fullfile(folder,string(j)+".png");
                exportgraphics(figures(j),filename,'Resolution',110); pixels=imread(filename);
                t.verifyGreaterThan(size(pixels,1),300); t.verifyGreaterThan(size(pixels,2),400);
                background=double(reshape(pixels(1,1,:),1,3))/255;
                expected=[0,0,0]; if Appearance=="light", expected=[1,1,1]; end
                t.verifyEqual(background,expected);
                if ~isempty(target)
                    t.verifyTrue(all(isfinite(target.XData))); % declared target, never filled actual gaps
                    if Scenario=="GAP" && ack
                        lines=findobj(figures(j),'Type','line','Marker','o');
                        t.verifyTrue(any(arrayfun(@(h) any(isnan(h.YData)),lines)));
                    end
                end
            end
            t.verifyEqual(r,before); t.verifyTrue(fsd.synthesis.validateSteeringSynthesisResult(r));
            if Scenario=="BUILDER_FAIL", t.verifyNumElements(figures,3); end
            if Scenario~="SINGLE", t.verifyTrue(isnan(r.selectedIndex)); end
        end
        function explicitEmptyAndOriginalKnots(t)
            s=steeringSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            q=targets{1}.definitionSI; q.type="CURVE_TARGET"; q.x=[-.01;-.005;0;.005;.01];
            q.value=[0;.01;0;-.01;0]; q.tolerance=.001;
            targets{1}=fsd.model.createDesignTarget(q,'rad','m'); d.targets=fsd.model.createSuspensionDesignTargets(targets);
            s=rebuildSteeringSpace(s,d);
            r=fsd.synthesis.runSteeringInverseSearch(s,struct('maxEvaluations',1));
            figures=fsd.synthesis.plotSteeringSynthesisResult(r); t.addTeardown(@() close(figures));
            nominal=findobj(figures,'Type','line','DisplayName','Target'); matched=false;
            for j=1:numel(nominal)
                if numel(nominal(j).XData)==5
                    t.verifyEqual(nominal(j).XData,q.x'); t.verifyEqual(nominal(j).YData,q.value'); matched=true;
                end
            end
            t.verifyTrue(matched);
            empty=fsd.synthesis.plotSteeringSynthesisResult(r,[]); t.addTeardown(@() close(empty));
            t.verifyNumElements(empty,3);
        end
    end
end

function r = reportFixture(scenario)
s=steeringSynthesisFixture(); d=s.specification.definitionSI;
if scenario=="BUILDER_FAIL"
    [old,~]=axleNullLinkFixture("UCA",1,"FWD",true); a=old.seedAxle;
    p=old.plan; p.referenceRackTravel_m=0;
    p.rack=struct('travel_m',0,'wheelTravel_m',[0,0],'travelLimits_m',[-.01,.01]);
    st=fsd.model.createSteeringSystem(a,1.6,'m');
    s=fsd.synthesis.createSteeringDesignSpace(a.leftGeometry,a.rightGeometry,st,old.specification,p);
else
    targets=d.targets.definitionSI.targets;
    if scenario=="HARD_FAIL"
        q=targets{6}.definitionSI; q.id="FAILED_HARD"; q.strength="HARD"; q.value=1; q.tolerance=0;
        targets{end+1,1}=fsd.model.createDesignTarget(q,'rad','m');
    elseif scenario=="GAP"
        p=s.plan; p.rack.solverOptions.MaxIterations=1; s=rebuildSteeringSpace(s,d,p);
        q=targets{6}.definitionSI; q.type="CURVE_TARGET"; q.x=[.003;.006]; q.value=0;
        targets{6}=fsd.model.createDesignTarget(q,'rad','m');
    end
    d.targets=fsd.model.createSuspensionDesignTargets(targets); s=rebuildSteeringSpace(s,d);
end
r=fsd.synthesis.runSteeringInverseSearch(s,struct('maxEvaluations',1));
end
