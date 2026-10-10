classdef TestDesignEvaluation < matlab.unittest.TestCase
    properties (TestParameter)
        ScalarCase = {"EXACT","WITHIN","OUTSIDE","BAND_INTERIOR","BAND_BOUNDARY","BAND_EXCEEDED", ...
            "UPPER","LOWER","ZERO_TARGET","ABS_TRANSFORM"}
        Grid = {[-.01;0;.01],[-.01;-.008;-.003;0;.007;.01],[.01;.004;0;-.006;-.01]}
        Metric = {"MOTION_RATIO","INSTALLATION_RATIO","SPRING_AXIAL_FORCE","SPRING_WHEEL_RESISTANCE","TANGENT_WHEEL_RATE"}
        Attack = {"COVERAGE","NORMALIZED","RMS","MAXIMUM","PASS","HARD","SOURCE","CANDIDATE", ...
            "SCORE","ORDER","ACTUAL","SPECIFICATION","INTERVALS","VALIDITY"}
        TargetAttack = {"VALUE","TOLERANCE","UNIT","SCOPE","CORNER","COORDINATE","SOURCE"}
    end
    methods (Test)
        function scalarKnownCases(t,ScalarCase)
            c = designEvaluationFixture(); extra = struct("x",.01,"value",.005,"tolerance",0, ...
                "normalizationScale",.01,"normalizationNote","Test displacement scale"); type = "POINT_TARGET";
            expectedDeviation = 0; expectedViolation = 0;
            switch ScalarCase
                case "WITHIN", extra.value = .004; extra.tolerance = .002; expectedDeviation = .001;
                case "OUTSIDE", extra.value = .004; extra.tolerance = .0005; expectedDeviation = .001; expectedViolation = .0005;
                case "ZERO_TARGET", extra.value = 0; expectedDeviation = .005; expectedViolation = .005;
                case "ABS_TRANSFORM", extra.x = -.01; extra.transform = "ABS";
                otherwise
                    if startsWith(ScalarCase,"BAND")
                        type = "VALUE_BAND"; extra = rmfield(extra,["value","tolerance"]); extra.lower = .004; extra.upper = .006;
                        if ScalarCase == "BAND_BOUNDARY", extra.upper = .005; end
                        if ScalarCase == "BAND_EXCEEDED", extra.upper = .004; expectedDeviation = .001; expectedViolation = .001; end
                    elseif ScalarCase == "UPPER"
                        type = "UPPER_BOUND"; extra = rmfield(extra,["value","tolerance"]); extra.upper = .004;
                        expectedDeviation = .001; expectedViolation = .001;
                    elseif ScalarCase == "LOWER"
                        type = "LOWER_BOUND"; extra = rmfield(extra,["value","tolerance"]); extra.lower = .006;
                        expectedDeviation = -.001; expectedViolation = .001;
                    end
            end
            target = designTargetFixture(type,"DAMPER_COMPRESSION",extra);
            spec = designSpecificationFixture(target); a = fsd.analysis.evaluateDesignCandidate(spec,c); r = a.targetAssessments{1};
            t.verifyEqual(r.deviation,expectedDeviation,"AbsTol",1e-15);
            t.verifyEqual(r.violation,expectedViolation,"AbsTol",1e-15);
            t.verifyEqual(r.normalizedResidual,expectedDeviation/.01,"AbsTol",1e-13);
            expectedStatus = "SAMPLED_PASS"; if expectedViolation > 0, expectedStatus = "SAMPLED_FAIL"; end
            t.verifyEqual(r.status,expectedStatus); t.verifyEqual(a.hardFeasibility,"NO_HARD_REQUIREMENTS");
            t.verifyTrue(fsd.analysis.validateDesignAssessment(a,spec,c));
        end
        function linearAndQuadraticKnownCurves(t,Grid)
            z = Grid; c = designEvaluationFixture(z,.5*z+3*z.^2);
            target = designTargetFixture("CURVE_TARGET","DAMPER_COMPRESSION", ...
                struct("x",z,"value",.5*z+3*z.^2,"tolerance",1e-14));
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c);
            t.verifyEqual(a.targetAssessments{1}.status,"SAMPLED_PASS");
            t.verifyEqual(a.targetAssessments{1}.domainCoverage,1);
            t.verifyEqual(a.targetAssessments{1}.actual,.5*sort(z)+3*sort(z).^2,"AbsTol",1e-15);
            linear = designEvaluationFixture(z,.5*z);
            target = designTargetFixture("CURVE_TARGET","DAMPER_COMPRESSION", ...
                struct("x",[-.01;.01],"value",[-.005;.005],"tolerance",1e-14));
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),linear);
            t.verifyEqual(a.targetAssessments{1}.status,"SAMPLED_PASS");
        end
        function domainWeightedRmsNotSampleCount(t)
            z = [-.01;-.009;0;.01]; c = designEvaluationFixture(z,.5*z);
            target = designTargetFixture("CURVE_TARGET","DAMPER_COMPRESSION",struct("x",[-.01;.01], ...
                "value",0,"tolerance",0,"normalizationScale",.005,"normalizationNote","Test scale"));
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c); r = a.targetAssessments{1};
            expected = sqrt((.001*(1+.81)/2+.009*.81/2+.01/2)/.02);
            t.verifyEqual(r.rmsNormalizedError,expected,"AbsTol",1e-13);
            t.verifyNotEqual(r.rmsNormalizedError,sqrt(mean((.5*z/.005).^2)));
        end
        function missingEndpointsAreNotExtrapolated(t)
            c = designEvaluationFixture();
            target = designTargetFixture("CURVE_BAND","DAMPER_COMPRESSION", ...
                struct("x",[-.02;.02],"lower",-.01,"upper",.01,"strength","HARD"));
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c); r = a.targetAssessments{1};
            t.verifyEqual(r.status,"PARTIALLY_EVALUATED"); t.verifyEqual(r.domainCoverage,.5,"AbsTol",1e-15);
            t.verifyEqual(r.unavailableSampleCount,2); t.verifyTrue(all(isnan(r.actual([1,end]))));
            t.verifyEqual(a.hardFeasibility,"INDETERMINATE_HARD_REQUIREMENTS");
        end
        function interiorAndBranchGapsNeverIntegrated(t)
            x = (-.02:.01:.02)'; target = designTargetFixture("CURVE_TARGET","DAMPER_COMPRESSION", ...
                struct("x",[x(1);x(end)],"value",0,"tolerance",0, ...
                "normalizationScale",1,"normalizationNote","Unit mathematical fixture"));
            r = designComparisonTestCall(target,x,[1;1;1000;1;1],[true;true;false;true;true],true(4,1));
            t.verifyEqual(r.domainCoverage,.5,"AbsTol",1e-14); t.verifyEqual(r.rmsNormalizedError,1);
            t.verifyEqual(r.availableIntervals,[-.02,-.01;.01,.02],"AbsTol",1e-14);
            r = designComparisonTestCall(target,[-.02;.02],[1;1],true(2,1),false);
            t.verifyEqual(r.status,"PARTIALLY_EVALUATED"); t.verifyEqual(r.domainCoverage,0);
            t.verifyTrue(isnan(r.rmsNormalizedError));
        end
        function partialHardViolationStillInvalidates(t)
            c = designEvaluationFixture(); target = designTargetFixture("CURVE_BAND","DAMPER_COMPRESSION", ...
                struct("x",[-.02;.02],"lower",-.001,"upper",.001,"strength","HARD"));
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c);
            t.verifyEqual(a.targetAssessments{1}.status,"PARTIALLY_EVALUATED");
            t.verifyEqual(a.hardFeasibility,"INFEASIBLE_FOR_SPECIFICATION");
        end
        function mechanicalAnalyticalMetrics(t,Metric)
            z = [-.01;0;.01]; c = designEvaluationFixture(z,-.5*z+3*z.^2);
            mr = -.5+6*z; fs = 30000*(.02-.5*z+3*z.^2);
            switch Metric
                case "MOTION_RATIO", expected = mr;
                case "INSTALLATION_RATIO", expected = abs(mr);
                case "SPRING_AXIAL_FORCE", expected = fs;
                case "SPRING_WHEEL_RESISTANCE", expected = fs.*mr;
                case "TANGENT_WHEEL_RATE", expected = 30000*mr.^2+6*fs;
            end
            target = designTargetFixture("CURVE_TARGET",Metric,struct("x",z,"value",expected,"tolerance",1e-6));
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c);
            t.verifyEqual(a.targetAssessments{1}.actual,expected,"AbsTol",1e-6);
            t.verifyEqual(a.targetAssessments{1}.status,"SAMPLED_PASS");
        end
        function numericalToleranceCannotRepairWheelRate(t)
            z = .01+[-1e-13;0;1e-13]; c = designEvaluationFixture(z,.5*z+3*z.^2);
            target = designTargetFixture("POINT_TARGET","TANGENT_WHEEL_RATE", ...
                struct("x",z(2),"value",1,"tolerance",1e12,"numericalTolerance",1e12));
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c); r = a.targetAssessments{1};
            t.verifyEqual(r.status,"NOT_EVALUATED"); t.verifyTrue(isnan(r.deviation));
            t.verifyTrue(contains(r.reasons,"UNAVAILABLE"));
        end
        function sourceCornerAndIdentityAreExplicit(t)
            c = designEvaluationFixture(); [~,d] = designTargetFixture("POINT_TARGET","MOTION_RATIO", ...
                struct("value",.5,"tolerance",.01,"scope",fsd.model.designScope("CORNER","FR")));
            target = fsd.model.createDesignTarget(d,"1","m");
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c);
            t.verifyEqual(a.targetAssessments{1}.reasons,"SCOPE_MISMATCH");
            d.scope = fsd.model.designScope("CORNER","FL"); d.requiredSourceIdentity = c.identity.definitionSI.sources{1};
            d.requiredSourceIdentity.id = "DIFFERENT_SOURCE"; target = fsd.model.createDesignTarget(d,"1","m");
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c);
            t.verifyEqual(a.targetAssessments{1}.reasons,"SOURCE_IDENTITY_MISMATCH");
        end
        function equalSampleCountsDoNotMakeSourcesCompatible(t)
            c = designEvaluationFixture(); target = designTargetFixture("POINT_TARGET","DAMPER_COMPRESSION", ...
                struct("sourceType","ACTUATION","value",0,"tolerance",1));
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c);
            t.verifyEqual(a.targetAssessments{1}.reasons,"SOURCE_TYPE_MISMATCH");
            t.verifyEqual(a.targetAssessments{1}.status,"NOT_EVALUATED");
        end
        function actualSamplesAreNeverInterpolatedForScalar(t)
            c = designEvaluationFixture(); target = designTargetFixture("POINT_TARGET","DAMPER_COMPRESSION", ...
                struct("x",.005,"value",.0025,"tolerance",1));
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c);
            t.verifyEqual(a.targetAssessments{1}.status,"NOT_EVALUATED");
            t.verifyEqual(a.targetAssessments{1}.reasons,"NO_RESULT_SAMPLE_AT_REQUESTED_COORDINATE");
        end
        function explicitScoreKeepsHardSeparate(t)
            c = designEvaluationFixture(); target = designTargetFixture("POINT_TARGET","DAMPER_COMPRESSION", ...
                struct("x",.01,"value",0,"tolerance",0,"normalizationScale",.005, ...
                "normalizationNote","Explicit test scale","weight",2));
            spec = designSpecificationFixture(target,true); a = fsd.analysis.evaluateDesignCandidate(spec,c);
            t.verifyEqual(a.compositeScore,1,"AbsTol",1e-14); t.verifyEqual(a.hardFeasibility,"NO_HARD_REQUIREMENTS");
            d = target.definitionSI; d.x = .02; d.metadata = target.metadata;
            target = fsd.model.createDesignTarget(d,"m","m");
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target,true),c);
            t.verifyTrue(isnan(a.compositeScore)); t.verifyEqual(a.compositeScoreStatus,"UNAVAILABLE_COVERAGE");
        end
        function tamperedAssessmentRejected(t,Attack)
            c = designEvaluationFixture(); target = designTargetFixture("CURVE_TARGET","DAMPER_COMPRESSION", ...
                struct("x",[-.01;0;.01],"value",0,"tolerance",0, ...
                "normalizationScale",.005,"normalizationNote","Test scale","weight",2));
            spec = designSpecificationFixture(target,true); a = fsd.analysis.evaluateDesignCandidate(spec,c); r = a.targetAssessments{1};
            switch Attack
                case "COVERAGE", r.domainCoverage = .5;
                case "NORMALIZED", r.normalizedResidual(1) = 4;
                case "RMS", r.rmsNormalizedError = 4;
                case "MAXIMUM", r.maximumAbsoluteError = 4;
                case "PASS", r.status = "SAMPLED_PASS";
                case "HARD", r.strength = "HARD";
                case "SOURCE", r.sourceIdentity.id = "OTHER";
                case "CANDIDATE", a.candidateIdentity.definitionSI.id = "OTHER";
                case "SCORE", a.compositeScore = 0;
                case "ORDER", r.actual = flipud(r.actual);
                case "ACTUAL", r.actual(2) = 1;
                case "SPECIFICATION", a.specificationIdentity.definitionSI.id = "OTHER";
                case "INTERVALS", r.availableIntervals = [0,1];
                case "VALIDITY", r.valid(1) = false;
            end
            a.targetAssessments{1} = r;
            t.verifyError(@() fsd.analysis.validateDesignAssessment(a,spec,c),"fsd:analysis:InvalidDesignAssessment");
        end
        function tamperedTargetRejected(t,TargetAttack)
            target = designTargetFixture("POINT_TARGET","DAMPER_COMPRESSION",struct("value",0,"tolerance",.001));
            switch TargetAttack
                case "VALUE", target.definitionSI.value = .1;
                case "TOLERANCE", target.definitionSI.tolerance = .1;
                case "UNIT", target.definitionSI.unit = "mm";
                case "SCOPE", target.definitionSI.scope.kind = "AXLE";
                case "CORNER", target.definitionSI.scope.id = "FR";
                case "COORDINATE", target.definitionSI.independentVariable = "RACK_TRAVEL";
                case "SOURCE", target.definitionSI.sourceId = "OTHER";
            end
            t.verifyError(@() fsd.model.validateDesignTarget(target),"fsd:model:InvalidDesignDefinition");
        end
        function candidateSourceIntegrityIsReconstructed(t)
            c = designEvaluationFixture(); d = c.definitionSI; d.metadata = c.metadata;
            d.sources{1}.result.damperCompression_m(2) = .1;
            forged = fsd.model.createDesignCandidate(d);
            t.verifyError(@() fsd.analysis.validateDesignCandidate(forged),"fsd:analysis:InvalidSpringDamperAnalysis");
        end
    end
end
