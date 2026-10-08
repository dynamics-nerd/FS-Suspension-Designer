classdef TestCurvatureReliability < matlab.unittest.TestCase
    properties (TestParameter)
        RockerSpacing = {1e-4,1e-8,1e-9}
    end
    methods (TestMethodSetup)
        function setup(testCase)
            oldPath = path;
            testCase.addTeardown(@() path(oldPath));
            addpath(fullfile(fileparts(fileparts(mfilename("fullpath"))),"src"));
        end
    end
    methods (Test)
        function exactSyntheticReproducerRejectsCurvatureButRetainsMR(testCase)
            m = springDamperFixture();
            z = 0.01+[-1e-13;0;1e-13];
            r = testCase.path(m,z,0.5*z+3*z.^2,0.1);
            testCase.verifyEqual(r.derivativeStatus(2),"UNAVAILABLE_NUMERICAL_RESOLUTION");
            testCase.verifyTrue(isnan(r.motionRatioDerivative_per_m(2)));
            testCase.verifyTrue(isnan(r.wheelRateGeometric_N_per_m(2)));
            testCase.verifyTrue(isnan(r.wheelRateTotal_N_per_m(2)));
            testCase.verifyEqual(r.motionRatioStatus(2),"AVAILABLE");
            testCase.verifyEqual(r.damperMotionRatio(2),0.56,"AbsTol",1e-5);
            testCase.verifyEqual(r.springAxialForce_N(2),759,"AbsTol",1e-10);
            testCase.verifyTrue(isfinite(r.springWheelResistance_N(2)));
            testCase.verifyTrue(isfinite(r.damperWheelResistance_N(2)));
            testCase.verifyTrue(isfinite(r.wheelRateElastic_N_per_m(2)));
            testCase.verifyEqual(r.stiffnessDiagnostic(2),"UNAVAILABLE");
            testCase.verifyTrue(isnan(r.metrics.maximumWheelRate_N_per_m));
            testCase.verifyTrue(fsd.analysis.validateSpringDamperSweepAnalysis(r,m));
        end
        function independentRockerBenchmark(testCase,RockerSpacing)
            [m,a,g] = springDamperFixture(); h = RockerSpacing;
            bump = fsd.kinematics.solveBumpSweep(g,0.01+[-h;0;h],"m");
            sweep = fsd.kinematics.solveActuationSweep(a,bump);
            aa = fsd.analysis.analyzeActuationSweep(a,sweep);
            r = fsd.analysis.analyzeSpringDamperSweep(m,a,sweep,aa,0.1,"m/s");
            expected = rockerWheelRateReference(0.01,30000,0.02);
            testCase.verifyEqual(expected,433.730954,"AbsTol",1e-6);
            q = r.derivativeDiagnostics;
            if h == 1e-4
                testCase.verifyEqual(r.wheelRateStatus(2),"AVAILABLE");
                testCase.verifyEqual(r.wheelRateTotal_N_per_m(2),expected,"AbsTol",0.03);
                testCase.verifyLessThanOrEqual(q.wheelRateAbsoluteError_N_per_m(2),q.wheelRateErrorLimit_N_per_m(2));
            else
                testCase.verifyEqual(r.derivativeStatus(2),"UNAVAILABLE_NUMERICAL_RESOLUTION");
                testCase.verifyTrue(isnan(r.wheelRateTotal_N_per_m(2)));
                testCase.verifyGreaterThan(q.curvatureAbsoluteError_per_m(2),q.curvatureErrorLimit_per_m(2));
                testCase.verifyTrue(isfinite(r.springWheelResistance_N(2)));
                testCase.verifyTrue(isfinite(r.damperWheelResistance_N(2)));
            end
            testCase.verifyTrue(fsd.analysis.validateSpringDamperSweepAnalysis(r,m,a));
        end
        function normalZeroCurvatureHasMixedAbsoluteBudget(testCase)
            m = springDamperFixture(); z = (-0.01:0.002:0.01)';
            r = testCase.path(m,z,0.5*z,0);
            testCase.verifyEqual(r.derivativeStatus,repmat("AVAILABLE",numel(z),1));
            testCase.verifyEqual(r.motionRatioDerivative_per_m,zeros(size(z)),"AbsTol",1e-10);
            testCase.verifyEqual(r.wheelRateTotal_N_per_m,repmat(7500,size(z)),"AbsTol",2e-7);
        end
        function sameFineSpacingCanBeResolvedAtSmallSampleScale(testCase)
            m = springDamperFixture(); z = [-1e-8;0;1e-8];
            r = testCase.path(m,z,0.5*z,0);
            testCase.verifyEqual(r.derivativeStatus(2),"AVAILABLE");
            testCase.verifyEqual(r.wheelRateTotal_N_per_m(2),7500,"AbsTol",1e-7);
            testCase.verifyTrue(r.derivativeDiagnostics.intrinsicCurvatureResolved(2));
        end
        function nonuniformExtremeMeshAmplifiesInputError(testCase)
            m = springDamperFixture(); z = 0.01+[0;1e-10;1e-8];
            r = testCase.path(m,z,0.5*z+3*z.^2,0);
            testCase.verifyEqual(r.derivativeStatus(2),"UNAVAILABLE_NUMERICAL_RESOLUTION");
            testCase.verifyGreaterThan(r.derivativeDiagnostics.curvatureAbsoluteError_per_m(2), ...
                r.derivativeDiagnostics.curvatureErrorLimit_per_m(2));
        end
        function decreasingWellResolvedQuadratic(testCase)
            m = springDamperFixture(); z = [0.01;0.006;0;-0.003;-0.01];
            r = testCase.path(m,z,0.5*z+3*z.^2,0);
            testCase.verifyEqual(r.derivativeStatus,repmat("AVAILABLE",5,1));
            testCase.verifyEqual(r.motionRatioDerivative_per_m,repmat(6,5,1),"AbsTol",1e-9);
        end
        function intrinsicCurvatureDoesNotHideBehindSmallForce(testCase)
            [~,a,~,definition,units] = springDamperFixture();
            z = 0.01+[-1e-13;0;1e-13]; c = 0.5*z+3*z.^2;
            for preload = [0,0.02]
                for stiffness = [300,30000]
                    definition.spring.preloadCompression = preload; definition.spring.rate = stiffness;
                    m = fsd.model.createSpringDamperModel(a,definition,units);
                    r = testCase.path(m,z,c,0);
                    testCase.verifyFalse(r.derivativeDiagnostics.intrinsicCurvatureResolved(2));
                    testCase.verifyTrue(isnan(r.wheelRateTotal_N_per_m(2)));
                end
            end
        end
        function wheelRateImpactIsSeparateFromIntrinsicCurvature(testCase)
            [~,a,~,d,u] = springDamperFixture();
            z = 0.01+[-5e-7;0;5e-7]; c = 0.1*z-0.2*z.^2;
            % At center choose preload so elastic and geometric terms cancel.
            mr = 0.096; d.spring.preloadCompression = mr^2/0.4-c(2);
            m = fsd.model.createSpringDamperModel(a,d,u);
            r = testCase.path(m,z,c,0);
            q = r.derivativeDiagnostics;
            testCase.verifyTrue(q.intrinsicCurvatureResolved(2));
            testCase.verifyFalse(q.wheelRateImpactResolved(2));
            testCase.verifyGreaterThan(q.wheelRateErrorLimit_N_per_m(2),0);
            testCase.verifyTrue(isnan(r.wheelRateTotal_N_per_m(2)));
            d.spring.preloadCompression = 0;
            m = fsd.model.createSpringDamperModel(a,d,u);
            lowForce = testCase.path(m,z,c,0);
            testCase.verifyTrue(lowForce.derivativeDiagnostics.intrinsicCurvatureResolved(2));
            testCase.verifyTrue(lowForce.derivativeDiagnostics.wheelRateImpactResolved(2));
            testCase.verifyTrue(isfinite(lowForce.wheelRateTotal_N_per_m(2)));
            testCase.verifyGreaterThan(q.geometricRateAbsoluteError_N_per_m(2), ...
                lowForce.derivativeDiagnostics.geometricRateAbsoluteError_N_per_m(2));
        end
        function unresolvedNominalCannotDefineMigration(testCase)
            m = springDamperFixture();
            % Three-point stencils centered at zero and clustered around 0.01.
            z = [-0.01;-1e-13;0;1e-13;0.01];
            r = testCase.path(m,z,0.5*z+3*z.^2,0);
            testCase.verifyFalse(r.staticReferenceAvailable);
            testCase.verifyTrue(all(isnan(r.wheelRateMigration_N_per_m)));
            testCase.verifyTrue(isnan(r.nominalWheelRate_N_per_m));
        end
        function unitsPreserveQualityAndAvailability(testCase)
            m = springDamperFixture(); z = 0.01+[-1e-13;0;1e-13]; c = 0.5*z+3*z.^2;
            r = testCase.path(m,z,c,0);
            mm = fsd.analysis.analyzePrescribedSpringDamperPath(m,1000*z,1000*c,0, ...
                struct("length","mm","velocity","mm/s"));
            testCase.verifyEqual(mm.derivativeStatus,r.derivativeStatus);
            testCase.verifyEqual(mm.motionRatioStatus,r.motionRatioStatus);
            testCase.verifyTrue(isnan(mm.wheelRateTotal_N_per_m(2)));
            testCase.verifyEqual(mm.derivativeDiagnostics.curvatureAbsoluteError_per_m(2), ...
                r.derivativeDiagnostics.curvatureAbsoluteError_per_m(2),"RelTol",0.01);
        end
        function mixedResolutionAndSourceGapsRemainDistinct(testCase)
            [m,a,g] = springDamperFixture();
            z = [0.0098;0.0099;0.01;0.01000001;0.01000002;0.0101;0.0102;0.5;0.02];
            b = fsd.kinematics.solveBumpSweep(g,z,"m");
            s = fsd.kinematics.solveActuationSweep(a,b);
            aa = fsd.analysis.analyzeActuationSweep(a,s);
            r = fsd.analysis.analyzeSpringDamperSweep(m,a,s,aa);
            testCase.verifyTrue(any(r.derivativeStatus == "AVAILABLE"));
            testCase.verifyEqual(r.derivativeStatus(4),"UNAVAILABLE_NUMERICAL_RESOLUTION");
            testCase.verifyEqual(r.derivativeStatus(8:9),["UNAVAILABLE_PATH_GAP";"UNAVAILABLE_PATH_GAP"]);
            testCase.verifyFalse(s.results(8).converged);
            testCase.verifyEqual(s.results(9).status,"NOT_ATTEMPTED");
            testCase.verifyTrue(isfinite(r.springAxialForce_N(4)));
            testCase.verifyTrue(all(isnan(r.springAxialForce_N(8:9))));
            testCase.verifyTrue(all(isnan(r.wheelRateTotal_N_per_m)));
        end
        function validatorsRejectForgedReliabilityAndRates(testCase)
            m = springDamperFixture(); z = 0.01+[-1e-13;0;1e-13];
            r = testCase.path(m,z,0.5*z+3*z.^2,0);
            for scenario = 1:8
                bad = r;
                switch scenario
                    case 1, bad.motionRatioDerivative_per_m(2) = 6;
                    case 2, bad.derivativeStatus(2) = "AVAILABLE";
                    case 3, bad.wheelRateTotal_N_per_m(2) = 13962;
                    case 4, bad.wheelRateGeometric_N_per_m(2) = 4554;
                    case 5, bad.metrics.maximumWheelRate_N_per_m = 13962;
                    case 6, bad.wheelRateMigration_N_per_m(2) = 0; bad.staticReferenceAvailable = true;
                    case 7, bad.derivativeDiagnostics.curvatureAbsoluteError_per_m(2) = 0;
                    case 8, bad.derivativeDiagnostics.secondWeights_per_m2(2,:) = 0;
                end
                testCase.verifyError(@() fsd.analysis.validateSpringDamperSweepAnalysis(bad,m), ...
                    "fsd:analysis:InvalidSpringDamperAnalysis");
            end
        end
        function partialCoverageRetainsForcesNotUnreliableRates(testCase)
            m = springDamperFixture();
            z = [0.0098;0.0099;0.01;0.01000001;0.01000002;0.0101;0.0102];
            r = testCase.path(m,z,0.5*z+3*z.^2,0.1);
            testCase.verifyEqual(r.derivativeStatus(4),"UNAVAILABLE_NUMERICAL_RESOLUTION");
            testCase.verifyFalse(r.wheelRateCoverageComplete);
            testCase.verifyGreaterThan(r.validWheelRateSampleCount,0);
            testCase.verifyLessThan(r.validWheelRateSampleCount,numel(z));
            testCase.verifyTrue(isnan(r.metrics.minimumWheelRate_N_per_m));
            testCase.verifyTrue(isnan(r.metrics.maximumWheelRate_N_per_m));
            testCase.verifyTrue(all(isfinite(r.springAxialForce_N)));
            testCase.verifyTrue(all(isfinite(r.springWheelResistance_N)));
            testCase.verifyTrue(all(isfinite(r.damperWheelResistance_N)));
            fig = figure("Visible","off"); testCase.addTeardown(@() close(fig));
            h = fsd.analysis.plotSpringDamperSweep(r,m,[],fig);
            lines = findobj(h.axes(4),"Type","line");
            testCase.verifyTrue(isnan(lines(1).YData(4)));
        end
        function unreliableCurvatureRespectsSpringBranches(testCase)
            m = springDamperFixture(0); z = -0.01+[-1e-13;0;1e-13];
            r = testCase.path(m,z,0.5*z+3*z.^2,0.1);
            testCase.verifyEqual(r.springStatus(2),"SPRING_UNSEATED");
            testCase.verifyEqual(r.springAxialForce_N(2),0);
            testCase.verifyEqual(r.wheelRateElastic_N_per_m(2),0);
            testCase.verifyTrue(isnan(r.wheelRateTotal_N_per_m(2)));
            testCase.verifyTrue(isfinite(r.damperWheelResistance_N(2)));
            z = [-1e-13;0;1e-13];
            r = testCase.path(m,z,0.5*z+3*z.^2,0);
            testCase.verifyEqual(r.springStatus(2),"SPRING_ENGAGEMENT_TRANSITION");
            testCase.verifyEqual(r.wheelRateStatus(2),"SPRING_ENGAGEMENT_TRANSITION");
            testCase.verifyTrue(isnan(r.wheelRateElastic_N_per_m(2)));
        end
    end
    methods (Static, Access = private)
        function r = path(m,z,c,v)
            r = fsd.analysis.analyzePrescribedSpringDamperPath(m,z,c,v, ...
                struct("length","m","velocity","m/s"));
        end
    end
end
