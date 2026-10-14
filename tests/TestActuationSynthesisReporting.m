classdef TestActuationSynthesisReporting < matlab.unittest.TestCase
    properties (TestParameter)
        Appearance={"dark","light"}
        Scenario={"SINGLE","MULTIPLE","NO_ELIGIBLE","DISABLED","GAP"}
    end
    methods (TestClassSetup)
        function setup(t)
            old=path; visible=get(groot,'DefaultFigureVisible');
            t.addTeardown(@()path(old)); t.addTeardown(@()set(groot,'DefaultFigureVisible',visible));
            root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'src'),fullfile(root,'examples'));
            set(groot,'DefaultFigureVisible','off');
        end
    end
    methods (Test)
        function storedEvidenceAndRealPng(t,Appearance,Scenario)
            s=actuationSynthesisFixture(); d=s.specification.definitionSI; p=s.plan;
            if Scenario=="NO_ELIGIBLE"
                c=fsd.model.createDesignConstraint(struct('id',"OUTSIDE",'type',"AXIS_ALIGNED_BOX",'strength',"HARD", ...
                    'scope',fsd.model.designScope('HARDPOINT','FL_DAMPER_CHASSIS','FL'), ...
                    'bounds',[.1,.2;.1,.2;.3,.4],'sourceNote',"Explicit rejected nominal-model control"),'m');
                d.constraints{end+1,1}=c;
            elseif Scenario=="DISABLED"
                d.compositeScore=false;
            elseif Scenario=="GAP"
                p.travel_m=[-.02;0;.4]; p.wheelVelocity_m_per_s=0;
            end
            s=rebuildActuationSpace(s,d,p); budget=1; if Scenario=="MULTIPLE", budget=3; end
            r=fsd.synthesis.runActuationInverseSearch(s,struct('maxEvaluations',budget,'maxIterations',1)); original=r;
            indices=1; if Scenario=="MULTIPLE", indices=(1:numel(r.search.records))'; end
            profile clear; profile on;
            figures=fsd.synthesis.plotActuationSynthesisResult(r,indices);
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["fsolve","fzero","solveBump","solveActuationSweep","solveActuationCore"])));
            t.addTeardown(@()close(figures)); t.verifyEqual(r,original); t.verifyGreaterThanOrEqual(numel(figures),3);
            for j=1:numel(figures)
                theme(figures(j),Appearance); legends=findall(figures(j),'Type','legend');
                for k=1:numel(legends), t.verifyEqual(string(legends(k).Location),"eastoutside"); end
                axesList=findall(figures(j),'Type','axes');
                for k=1:numel(axesList)
                    t.verifyEqual(axesList(k).XAxis.Exponent,int32(0)); t.verifyEqual(axesList(k).YAxis.Exponent,int32(0));
                end
            end
            root=fileparts(fileparts(mfilename('fullpath'))); folder=fullfile(root,'output','v0.15-tests-qa');
            if ~isfolder(folder), mkdir(folder); end
            selected=[1,2,min(4,numel(figures)),numel(figures)];
            for j=unique(selected)
                toolbar=findall(figures(j),'Type','axes'); for k=1:numel(toolbar), toolbar(k).Toolbar.Visible='off'; end
                file=fullfile(folder,Appearance+"-"+Scenario+"-"+j+".png");
                exportgraphics(figures(j),file,'Resolution',90,'Padding','figure'); pixels=imread(file);
                t.verifyGreaterThan(size(pixels,1),500); t.verifyGreaterThan(size(pixels,2),900);
                background=double(reshape(pixels(1,1,1:3),1,3))/255;
                if Appearance=="dark", t.verifyLessThan(mean(background),.2);
                else, t.verifyGreaterThan(mean(background),.8); end
            end
            if Scenario=="GAP"
                current=find(startsWith(string({figures.Name}),"Actuation curves"),1);
                t.verifyNotEmpty(current); lines=findall(figures(current),'Type','line');
                t.verifyTrue(any(arrayfun(@(line)any(isnan(line.YData)),lines)));
            end
            if ismember(Scenario,["NO_ELIGIBLE","DISABLED"]), t.verifyTrue(isnan(r.selectedIndex)); end
        end
        function emptySelectionStillReportsHistory(t)
            s=actuationSynthesisFixture(); r=fsd.synthesis.runActuationInverseSearch(s,struct('maxEvaluations',1));
            figures=fsd.synthesis.plotActuationSynthesisResult(r,[]); t.addTeardown(@()close(figures));
            t.verifyNumElements(figures,3); t.verifyEqual(figures(1).UserData,r);
        end
        function rearAxisDisplayIsLocalNotABearing(t)
            s=actuationSynthesisFixture('PULLROD','RR');
            r=fsd.synthesis.runActuationInverseSearch(s,struct('maxEvaluations',1));
            figures=fsd.synthesis.plotActuationSynthesisResult(r,1); t.addTeardown(@()close(figures));
            f=figures(end); e=r.search.records{1}; index=f.UserData.sampleIndex;
            centre=e.actuationEvidence.sweep.results(index).diagnostics.rockerCircleCenter_m;
            line=findall(f,'Type','line','LineStyle','-.'); t.verifyNumElements(line,1);
            t.verifyEqual([mean(line.XData),mean(line.YData),mean(line.ZData)],centre,'AbsTol',1e-12);
            t.verifyEqual(e.actuation.rocker.axis.point_m(1),0); t.verifyGreaterThan(centre(1),1);
            dots=findall(f,'Type','scatter','Visible','off'); t.verifyNumElements(dots,1);
            t.verifyEqual(r.search.records{1}.geometry,s.seed);
        end
    end
end
