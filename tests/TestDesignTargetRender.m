classdef TestDesignTargetRender < matlab.unittest.TestCase
    properties (TestParameter)
        Appearance = {"dark","light"}
        Visibility = {"off","on"}
        Scenario = {"PEAK","VALLEY","ORDER_AB","ORDER_BA","PARTIAL","GAP"}
    end
    methods (TestMethodSetup)
        function restoreVisibility(t)
            old = get(groot,"DefaultFigureVisible");
            t.addTeardown(@() set(groot,"DefaultFigureVisible",old));
        end
    end
    methods (Test)
        function visibleAndHiddenExport(t,Appearance,Visibility)
            set(groot,"DefaultFigureVisible",Visibility);
            [s,c] = renderFixture("PEAK");
            fig = fsd.analysis.plotDesignTargetEvaluation(s,c); t.addTeardown(@() close(fig));
            theme(fig,Appearance); set(fig,"Position",[100,100,1100,700]);
            filename = string(tempname)+".png"; t.addTeardown(@() delete(filename));
            before = fsd.analysis.evaluateDesignCandidate(s,c);
            r = designTargetRenderCheck(fig,filename);
            designExteriorTextCheck(fig,filename);
            t.verifyEqual(r.theme,Appearance); t.verifyGreaterThan(r.pngContrast,3.5);
            t.verifyEqual(fsd.analysis.evaluateDesignCandidate(s,c),before);
        end
        function exportedShapesGridsAndGaps(t,Appearance,Scenario)
            set(groot,"DefaultFigureVisible","off"); [s,c] = renderFixture(Scenario);
            fig = fsd.analysis.plotDesignTargetEvaluation(s,c); t.addTeardown(@() close(fig));
            theme(fig,Appearance); set(fig,"Position",[100,100,1100,700]);
            lines = findobj(fig,"Type","line"); beforeX = {lines.XData}; beforeY = {lines.YData};
            filename = string(tempname)+".png"; t.addTeardown(@() delete(filename));
            r = designTargetRenderCheck(fig,filename);
            designExteriorTextCheck(fig,filename);
            t.verifyEqual(r.theme,Appearance);
            t.verifyEqual({lines.XData},beforeX); t.verifyEqual({lines.YData},beforeY);
            targetLine = findobj(fig,"Type","line","DisplayName","Target");
            actual = findobj(targetLine.Parent,"Type","line","Marker","o");
            if Scenario == "GAP"
                t.verifyTrue(any(isnan(actual.YData)));
            elseif Scenario == "PARTIAL"
                t.verifySubstring(actual.DisplayName,'domain coverage 50.0%');
            end
        end
        function apiDefaultExteriorTextAndResize(t,Visibility)
            set(groot,"DefaultFigureVisible",Visibility);
            [s,c] = renderFixture("ORDER_AB");
            fig = fsd.analysis.plotDesignTargetEvaluation(s,c); t.addTeardown(@() close(fig));
            % Deliberately NO theme call: the PUBLIC API must be export-safe.
            set(fig,"WindowStyle","normal","WindowState","normal");
            filename = string(tempname)+".png"; t.addTeardown(@() delete(filename));
            lines = findobj(fig,"Type","line"); x = {lines.XData}; y = {lines.YData};
            dimensions = zeros(2,2); iteration = 0;
            for windowSize = [1100,900;700,600]
                iteration = iteration+1;
                set(fig,"Position",[100,100,windowSize']);
                % Visible-window resize reaches the frontend asynchronously.
                if Visibility == "on", drawnow; pause(1); end
                designTargetRenderCheck(fig,filename);
                r = designExteriorTextCheck(fig,filename);
                t.verifyGreaterThanOrEqual(min(r.textContrast),4.5);
                t.verifyEqual({lines.XData},x); t.verifyEqual({lines.YData},y);
                pixels = imread(filename); dimensions(iteration,:) = [size(pixels,1),size(pixels,2)];
            end
            t.verifyNotEqual(dimensions(1,:),dimensions(2,:),"Resize must change actual PNG dimensions.");
        end
        function pixelOracleRejectsGrayTextOnWhiteMargins(t)
            set(groot,"DefaultFigureVisible","off"); [s,c] = renderFixture("PEAK");
            fig = fsd.analysis.plotDesignTargetEvaluation(s,c); t.addTeardown(@() close(fig));
            theme(fig,"dark"); set(fig,"Position",[100,100,1100,700]);
            filename = string(tempname)+".png"; t.addTeardown(@() delete(filename));
            designTargetRenderCheck(fig,filename); r = designExteriorTextCheck(fig,filename);
            pixels = imread(filename); background = uint8(round(255*r.pngBackgroundRGB(1,:)));
            mask = all(pixels == reshape(background,1,1,3),3);
            for channel = 1:3
                plane = pixels(:,:,channel); plane(mask) = 255; pixels(:,:,channel) = plane;
            end
            imwrite(pixels,filename); % Negative control: retain gray glyphs, whiten canvas.
            t.verifyError(@() designExteriorTextCheck(fig,filename),"fsd:tests:ExteriorTextContrast");
        end
    end
end

function [spec,candidates] = renderFixture(scenario)
x = [-.01;0;.01]; v = [0;.005;0];
candidates = designEvaluationFixture([-.01;.01],[0;0]);
if scenario == "VALLEY", v = -v; end
if startsWith(scenario,"ORDER")
    b = designEvaluationFixture([-.01;-.005;0;.005;.01],zeros(5,1));
    d = b.definitionSI; d.metadata = b.metadata; d.id = "DENSE_B"; b = fsd.model.createDesignCandidate(d);
    candidates = {candidates;b}; if scenario == "ORDER_BA", candidates = flipud(candidates); end
elseif scenario == "PARTIAL"
    x = [-.02;-.01;0;.01;.02]; v = [0;.001;.005;.001;0]; candidates = designEvaluationFixture();
elseif scenario == "GAP"
    [~,act,~,d,u] = springDamperFixture(); d.damper.minimumLength = act.damper.staticLength_m-.003;
    model = fsd.model.createSpringDamperModel(act,d,u); x = [-.02;-.01;0;.01;.02]; v = [0;.005;0;0;0];
    r = fsd.analysis.analyzePrescribedSpringDamperPath(model,x,v,0,struct("length","m","velocity","m/s"));
    candidates = fsd.model.createDesignCandidate(struct("id","GAP_CANDIDATE","sources",{{ ...
        struct("id","MECH_FL","type","MECHANICAL","model",model,"result",r)}}));
end
target = designTargetFixture("CURVE_TARGET","DAMPER_COMPRESSION",struct("x",x,"value",v,"tolerance",.001));
spec = designSpecificationFixture(target);
end
