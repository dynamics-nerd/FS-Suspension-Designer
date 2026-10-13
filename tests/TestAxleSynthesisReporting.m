classdef TestAxleSynthesisReporting < matlab.unittest.TestCase
    properties (TestParameter)
        Appearance={"dark","light"}
        Scenario={"SINGLE","HARD_FAIL","BUILDER_FAIL","GAP"}
    end
    methods (TestMethodSetup)
        function setup(t)
            old=path; visible=get(groot,'DefaultFigureVisible');
            t.addTeardown(@() path(old)); t.addTeardown(@() set(groot,'DefaultFigureVisible',visible));
            addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'src')); set(groot,'DefaultFigureVisible','off');
        end
    end
    methods (Test)
        function firstPngAndNativeTargets(t,Appearance,Scenario)
            r=reportFixture(Scenario); before=r; profile clear; profile on;
            figures=fsd.synthesis.plotAxleSynthesisResult(r); profile off; t.addTeardown(@() close(figures));
            info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["fsolve","fzero","solveBump","solveAxleRoll"])));
            t.verifyFalse(any(contains(names,'compareDesignCandidates')));
            folder=string(tempname); mkdir(folder); t.addTeardown(@() rmdir(folder,'s'));
            for k=1:numel(figures)
                theme(figures(k),Appearance); file=fullfile(folder,string(k)+".png");
                exportgraphics(figures(k),file,'Resolution',110);
                pixels=imread(file); t.verifyGreaterThan(size(pixels,1),300); t.verifyGreaterThan(size(pixels,2),400);
                if k<=2
                    t.verifyEqual(figures(k).UserData,r);
                    % Native figure.Color can differ from the exported exterior.
                    % Use actual PNG background, as the historical F03 oracle does.
                    background=double(reshape(pixels(1,1,:),1,3))/255;
                    expected=[0,0,0]; if Appearance=="light", expected=[1,1,1]; end
                    t.verifyEqual(background,expected);
                    text=findall(figures(k),'Type','text');
                    for j=1:numel(text)
                        if isempty(text(j).String), continue; end
                        t.verifyGreaterThanOrEqual(contrast(text(j).Color,background),4.5);
                    end
                end
                target=findobj(figures(k),'Type','line','DisplayName','Target');
                if ~isempty(target)
                    designTargetRenderCheck(figures(k),file); designExteriorTextCheck(figures(k),file);
                    lines=findobj(figures(k),'Type','line','Marker','o');
                    if Scenario=="GAP" && contains(string(figures(k).Name),"FR_CAMBER")
                        t.verifyTrue(any(arrayfun(@(h) any(isnan(h.YData)),lines)));
                    end
                end
            end
            t.verifyEqual(r,before); t.verifyTrue(fsd.synthesis.validateAxleSynthesisResult(r));
            if Scenario=="BUILDER_FAIL", t.verifyNumElements(figures,2); end
            if Scenario~="SINGLE", t.verifyTrue(isnan(r.selectedIndex)); end
        end
        function targetsKeepOriginalKnots(t)
            s=axleSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            q=targets{2}.definitionSI; q.type="CURVE_TARGET"; q.x=[-.01;-.005;0;.005;.01]; q.value=[0;.01;0;-.01;0]; q.tolerance=.001;
            targets{2}=fsd.model.createDesignTarget(q,'rad','m'); d.targets=fsd.model.createSuspensionDesignTargets(targets); s=rebuildAxleSpace(s,d);
            r=fsd.synthesis.runAxleInverseSearch(s,struct('maxEvaluations',1)); figures=fsd.synthesis.plotAxleSynthesisResult(r); t.addTeardown(@() close(figures));
            target=findobj(figures,'Type','line','DisplayName','Target'); matched=false;
            for k=1:numel(target)
                if numel(target(k).XData)==5
                    t.verifyEqual(target(k).XData,q.x'); t.verifyEqual(target(k).YData,q.value'); matched=true;
                end
            end
            t.verifyTrue(matched);
        end
        function explicitEmptyIndices(t)
            r=reportFixture("SINGLE"); figures=fsd.synthesis.plotAxleSynthesisResult(r,[]); t.addTeardown(@() close(figures));
            t.verifyNumElements(figures,2);
        end
    end
end

function r = reportFixture(scenario)
s=axleSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
switch scenario
    case "HARD_FAIL"
        q=targets{2}.definitionSI; q.id="FAILED_HARD"; q.strength="HARD"; q.value=1; q.tolerance=0;
        targets{end+1,1}=fsd.model.createDesignTarget(q,'rad','m');
    case "GAP"
        plan=s.plan; plan.rightBump.solverOptions=struct('MaxIterations',1); s=rebuildAxleSpace(s,d,plan);
        q=targets{2}.definitionSI; q.type="CURVE_TARGET"; q.x=[-.01;0;.01]; q.value=0; q.tolerance=1;
        targets{2}=fsd.model.createDesignTarget(q,'rad','m');
    case "BUILDER_FAIL"
        [s,~]=axleNullLinkFixture("UCA",1,"FWD",true);
        r=fsd.synthesis.runAxleInverseSearch(s,struct('maxEvaluations',1)); return;
end
d.targets=fsd.model.createSuspensionDesignTargets(targets); s=rebuildAxleSpace(s,d);
r=fsd.synthesis.runAxleInverseSearch(s,struct('maxEvaluations',1));
end

function value = contrast(a,b)
a=linear(a); b=linear(b); weights=[.2126,.7152,.0722]; la=sum(a.*weights); lb=sum(b.*weights);
value=(max(la,lb)+.05)/(min(la,lb)+.05);
end
function value = linear(value)
low=value<=.04045; value(low)=value(low)/12.92; value(~low)=((value(~low)+.055)/1.055).^2.4;
end
