classdef TestDesignTargetPlotAudit < matlab.unittest.TestCase
    properties (TestParameter)
        Shape = {"PEAK","VALLEY","DESCENDING"}
        Tolerance = {"SCALAR","PER_KNOT"}
        Band = {"VALUE_BAND","CURVE_BAND","UPPER_BOUND","LOWER_BOUND"}
    end
    methods (TestMethodSetup)
        function invisibleFigures(t)
            old = get(groot,"DefaultFigureVisible");
            set(groot,"DefaultFigureVisible","off");
            t.addTeardown(@() set(groot,"DefaultFigureVisible",old));
        end
    end
    methods (Test)
        function mandatoryFiveMillimeterPeak(t)
            c = designEvaluationFixture([-.01;.01],[0;0]);
            x = [-.01;0;.01]; v = [0;.005;0];
            target = designTargetFixture("CURVE_TARGET","DAMPER_COMPRESSION", ...
                struct("x",x,"value",v,"tolerance",.001));
            spec = designSpecificationFixture(target);
            a = fsd.analysis.evaluateDesignCandidate(spec,c);
            t.verifyEqual(a.targetAssessments{1}.status,"SAMPLED_PASS");
            t.verifyEqual(a.targetAssessments{1}.actual,[0;0]);
            fig = fsd.analysis.plotDesignTargetEvaluation(spec,c); t.addTeardown(@() close(fig));
            t.verifyEqual(lineData(fig,"Target","XData"),x);
            t.verifyEqual(lineData(fig,"Target","YData"),v);
            t.verifyEqual(lineData(fig,"Lower acceptance","YData"),v-.001,"AbsTol",1e-15);
            t.verifyEqual(lineData(fig,"Upper acceptance","YData"),v+.001,"AbsTol",1e-15);
            actual = actualLine(fig,c.definitionSI.id);
            t.verifyEqual(actual.XData(:),[-.01;.01]); t.verifyEqual(actual.YData(:),[0;0]);
        end
        function declaredShapesAndTolerancesKeepEveryKnot(t,Shape,Tolerance)
            x = [-.02;-.01;0;.005;.02]; v = [0;.003;.005;.001;0];
            if Shape == "VALLEY", v = -v;
            elseif Shape == "DESCENDING", x = flipud(x); v = flipud(v); end
            tol = .001; if Tolerance == "PER_KNOT", tol = [.001;.002;.0005;.001;.003]; end
            target = designTargetFixture("CURVE_TARGET","DAMPER_COMPRESSION", ...
                struct("x",x,"value",v,"tolerance",tol));
            c = designEvaluationFixture([-.02;.02],[0;0]);
            fig = fsd.analysis.plotDesignTargetEvaluation(designSpecificationFixture(target),c);
            t.addTeardown(@() close(fig));
            t.verifyEqual(lineData(fig,"Target","XData"),x);
            t.verifyEqual(lineData(fig,"Target","YData"),v);
            t.verifyEqual(lineData(fig,"Lower acceptance","YData"),v-tol,"AbsTol",1e-15);
            t.verifyEqual(lineData(fig,"Upper acceptance","YData"),v+tol,"AbsTol",1e-15);
        end
        function allBandAndBoundTypesUseOriginalDefinitions(t,Band)
            x = .01; lower = -.001; upper = .002;
            if Band == "CURVE_BAND"
                x = [-.01;0;.01]; lower = [-.001;-.004;-.002]; upper = [.002;.005;.001];
            end
            d = struct("x",x);
            if Band ~= "UPPER_BOUND", d.lower = lower; end
            if Band ~= "LOWER_BOUND", d.upper = upper; end
            target = designTargetFixture(Band,"DAMPER_COMPRESSION",d);
            fig = fsd.analysis.plotDesignTargetEvaluation(designSpecificationFixture(target),designEvaluationFixture());
            t.addTeardown(@() close(fig));
            t.verifyEqual(lineData(fig,"Lower acceptance","XData"),x);
            t.verifyEqual(lineData(fig,"Upper acceptance","XData"),x);
            if Band ~= "UPPER_BOUND", t.verifyEqual(lineData(fig,"Lower acceptance","YData"),lower); end
            if Band ~= "LOWER_BOUND", t.verifyEqual(lineData(fig,"Upper acceptance","YData"),upper); end
        end
        function reversedCandidateOrderCannotChangeDeclaredTarget(t)
            x = [-.01;0;.01]; v = [0;.005;0];
            target = designTargetFixture("CURVE_TARGET","DAMPER_COMPRESSION",struct("x",x,"value",v,"tolerance",.001));
            spec = designSpecificationFixture(target);
            a = designEvaluationFixture([-.01;.01],[0;0]);
            b = designEvaluationFixture([-.01;-.005;0;.005;.01],zeros(5,1));
            d = b.definitionSI; d.metadata = b.metadata; d.id = "DENSE_B"; b = fsd.model.createDesignCandidate(d);
            first = fsd.analysis.plotDesignTargetEvaluation(spec,{a;b}); t.addTeardown(@() close(first));
            second = fsd.analysis.plotDesignTargetEvaluation(spec,{b;a}); t.addTeardown(@() close(second));
            for name = ["Target","Lower acceptance","Upper acceptance"]
                t.verifyEqual(lineData(first,name,"XData"),lineData(second,name,"XData"));
                t.verifyEqual(lineData(first,name,"YData"),lineData(second,name,"YData"));
            end
            t.verifyEqual(actualLine(first,a.definitionSI.id).XData(:),[-.01;.01]);
            t.verifyEqual(actualLine(first,b.definitionSI.id).XData(:),[-.01;-.005;0;.005;.01]);
            comparison = fsd.analysis.compareDesignCandidates(spec,{a;b});
            t.verifyEqual(comparison.assessments{1}.targetAssessments{1}.status,"SAMPLED_PASS");
            t.verifyEqual(comparison.assessments{2}.targetAssessments{1}.status,"SAMPLED_FAIL");
        end
        function partialDomainShowsEntireDeclaredTargetAndCoverage(t)
            x = [-.02;-.01;0;.01;.02]; v = [0;.001;.005;.001;0];
            target = designTargetFixture("CURVE_TARGET","DAMPER_COMPRESSION",struct("x",x,"value",v,"tolerance",.01));
            c = designEvaluationFixture(); spec = designSpecificationFixture(target);
            a = fsd.analysis.evaluateDesignCandidate(spec,c);
            fig = fsd.analysis.plotDesignTargetEvaluation(spec,c); t.addTeardown(@() close(fig));
            t.verifyEqual(lineData(fig,"Target","XData"),x);
            t.verifyEqual(lineData(fig,"Target","YData"),v);
            actual = actualLine(fig,c.definitionSI.id);
            t.verifySubstring(actual.DisplayName,'domain coverage 50.0%');
            t.verifyEqual(a.targetAssessments{1}.domainCoverage,.5,"AbsTol",1e-15);
            t.verifyEqual(actual.XData(isfinite(actual.YData))',[-.01;0;.01]);
        end
        function nativeInternalMechanicalGapNeverConnectsActual(t)
            [~,act,~,d,u] = springDamperFixture();
            d.damper.minimumLength = act.damper.staticLength_m-.003;
            model = fsd.model.createSpringDamperModel(act,d,u); x = [-.02;-.01;0;.01;.02];
            compression = [0;.005;0;0;0];
            r = fsd.analysis.analyzePrescribedSpringDamperPath(model,x,compression,0,struct("length","m","velocity","m/s"));
            c = fsd.model.createDesignCandidate(struct("id","GAP_CANDIDATE","sources",{{ ...
                struct("id","MECH_FL","type","MECHANICAL","model",model,"result",r)}}));
            target = designTargetFixture("CURVE_TARGET","DAMPER_COMPRESSION",struct("x",x,"value",compression,"tolerance",.001));
            spec = designSpecificationFixture(target); a = fsd.analysis.evaluateDesignCandidate(spec,c);
            fig = fsd.analysis.plotDesignTargetEvaluation(spec,c); t.addTeardown(@() close(fig));
            actual = actualLine(fig,c.definitionSI.id);
            t.verifyEqual(actual.YData(:),[0;NaN;0;0;0]);
            t.verifyEqual(a.targetAssessments{1}.valid,[true;false;true;true;true]);
            t.verifyEqual(a.targetAssessments{1}.domainCoverage,.5,"AbsTol",1e-15);
            t.verifyEqual(lineData(fig,"Target","YData"),compression);
        end
        function morePhysicalSamplesDoNotInventTargetKnots(t)
            x = [-.01;.01]; target = designTargetFixture("CURVE_TARGET","DAMPER_COMPRESSION", ...
                struct("x",x,"value",[-.005;.005],"tolerance",.001));
            z = (-.01:.002:.01)'; c = designEvaluationFixture(z,.5*z);
            fig = fsd.analysis.plotDesignTargetEvaluation(designSpecificationFixture(target),c); t.addTeardown(@() close(fig));
            t.verifyEqual(lineData(fig,"Target","XData"),x);
            t.verifyEqual(actualLine(fig,c.definitionSI.id).XData(:),z);
        end
    end
end

function line = actualLine(fig,id)
lines = findobj(fig,"Type","line"); names = string({lines.DisplayName});
line = lines(startsWith(names,id+" —"));
end

function data = lineData(fig,name,property)
line = findobj(fig,"Type","line","DisplayName",name); data = line.(property)(:);
end
