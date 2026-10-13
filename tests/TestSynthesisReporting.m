classdef TestSynthesisReporting < matlab.unittest.TestCase
    properties (TestParameter)
        Appearance={"dark","light"}
    end
    methods (TestMethodSetup)
        function setup(t)
            old=path; visible=get(groot,'DefaultFigureVisible');
            t.addTeardown(@() path(old)); t.addTeardown(@() set(groot,'DefaultFigureVisible',visible));
            addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'src')); set(groot,'DefaultFigureVisible','off');
        end
    end
    methods (Test)
        function nativePngAndNoSolves(t,Appearance)
            [s,o]=synthesisFixture(); r=fsd.synthesis.runInverseSearch(s,o);
            profile clear; profile on; figures=fsd.synthesis.plotSynthesisResult(r,[1;r.selectedIndex]); profile off;
            t.addTeardown(@() close(figures)); info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["solveBump","fsolve","fzero"])));
            t.verifyNumElements(figures,3);
            file=string(tempname)+".png"; t.addTeardown(@() delete(file));
            for i=1:numel(figures)
                theme(figures(i),Appearance);
                % First export is immediate: do not conceal a theme-init defect.
                exportgraphics(figures(i),file,'Resolution',100); pixels=imread(file);
                background=double(reshape(pixels(1,1,:),1,3))/255;
                if Appearance=="dark", t.verifyEqual(background,[0,0,0]); else, t.verifyEqual(background,[1,1,1]); end
                firstSize=[size(pixels,1),size(pixels,2)];
                % Frontend mounting/resizing is asynchronous even when hidden.
                % QA only; production theme initialization never waits.
                set(figures(i),'WindowStyle','normal','WindowState','normal','Units','pixels');
                drawnow; pause(1);
                set(figures(i),'Position',[50,50,1100,900]); drawnow; pause(1);
                exportgraphics(figures(i),file,'Resolution',100); pixels=imread(file);
                t.verifyGreaterThan(size(pixels,1),500);
                t.verifyNotEqual([size(pixels,1),size(pixels,2)],firstSize,'Resize must change the real PNG, not only Position.');
                if i>1
                    designTargetRenderCheck(figures(i),file); designExteriorTextCheck(figures(i),file);
                end
            end
            t.verifyTrue(fsd.synthesis.validateSynthesisResult(r));
        end
    end
end
