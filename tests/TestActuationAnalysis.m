classdef TestActuationAnalysis < matlab.unittest.TestCase
    properties
        OriginalPath
    end

    methods (TestMethodSetup)
        function addSourceToPath(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.OriginalPath = path;
            testCase.addTeardown(@() path(testCase.OriginalPath));
            addpath(fullfile(projectRoot, "src"));
        end
    end

    methods (Test)
        function computesCanonicalMotionRatioAndMigration(testCase)
            [~, ~, analysis] = testCase.solveSweep((-20:2:20)');
            testCase.verifyEqual(analysis.motionRatioStatus, "AVAILABLE");
            testCase.verifyEqual(analysis.installationRatio, ...
                abs(analysis.damperMotionRatio), "AbsTol", 1e-14);
            zeroIndex = find(analysis.achievedWheelTravel_m == 0);
            testCase.verifyEqual(analysis.motionRatioMigration(zeroIndex), ...
                0, "AbsTol", 1e-14);
            testCase.verifyEqual(analysis.staticDamperMotionRatio, ...
                analysis.damperMotionRatio(zeroIndex));
        end

        function finiteDifferenceMatchesIndependentAnalyticDerivative(testCase)
            [~, ~, analysis] = testCase.solveSweep((-20:2:20)');
            expected = arrayfun(@testCase.analyticMotionRatio, ...
                analysis.achievedWheelTravel_m);
            % Interior errors follow the documented second-order stencil.
            testCase.verifyEqual(analysis.damperMotionRatio(2:end-1), ...
                expected(2:end-1), "AbsTol", 4e-4);
            testCase.verifyEqual(analysis.damperMotionRatio([1,end]), ...
                expected([1,end]), "AbsTol", 7e-4);
            zeroIndex = find(analysis.achievedWheelTravel_m == 0);
            testCase.verifyEqual(analysis.damperMotionRatio(zeroIndex), ...
                expected(zeroIndex), "AbsTol", 2e-4);
        end

        function statesMatchIndependentClosedFormGeometry(testCase)
            [~, sweep, ~] = testCase.solveSweep([-10;0;10]);
            for index = 1:3
                [theta, damperLength, compression] = ...
                    testCase.analyticState( ...
                    sweep.achievedWheelTravel_m(index));
                testCase.verifyEqual(sweep.rockerAngle_rad(index), ...
                    theta, "AbsTol", 2e-13);
                testCase.verifyEqual(sweep.damperLength_m(index), ...
                    damperLength, "AbsTol", 2e-13);
                testCase.verifyEqual(sweep.damperCompression_m(index), ...
                    compression, "AbsTol", 2e-13);
            end
        end

        function nonuniformSpacingUsesSecondOrderStencil(testCase)
            targets_mm = [-20;-11;-3;0;4;13;20];
            [~, ~, analysis] = testCase.solveSweep(targets_mm);
            expected = arrayfun(@testCase.analyticMotionRatio, ...
                analysis.achievedWheelTravel_m);
            testCase.verifyEqual(analysis.damperMotionRatio, expected, ...
                "AbsTol", 7e-3);
        end

        function duplicateWheelTravelLeavesStatesValidButRatioUnavailable(testCase)
            [~, sweep, analysis] = testCase.solveSweep([0;10;0]);
            testCase.verifyTrue(sweep.allConverged);
            testCase.verifyEqual(analysis.motionRatioStatus, ...
                "UNAVAILABLE_NONMONOTONIC_WHEEL_TRAVEL");
            testCase.verifyTrue(all(isnan(analysis.damperMotionRatio)));
            testCase.verifyTrue(all(isfinite(analysis.damperCompression_m)));
        end

        function decreasingSweepSupportsRequestedStaticReference(testCase)
            [~,~,analysis] = testCase.solveSweep([20;10;0;-10;-20]);
            testCase.verifyEqual(analysis.motionRatioStatus,"AVAILABLE");
            testCase.verifyEqual(analysis.staticReferenceIndex,3);
            testCase.verifyEqual(analysis.motionRatioMigration(3),0, ...
                "AbsTol",1e-14);
        end

        function nonmonotonicDistinctSweepSuppressesAllDerivatives(testCase)
            [~,~,analysis] = testCase.solveSweep([-10;0;10;5]);
            testCase.verifyEqual(analysis.motionRatioStatus, ...
                "UNAVAILABLE_NONMONOTONIC_WHEEL_TRAVEL");
            testCase.verifyTrue(all(isnan(analysis.damperMotionRatio)));
            testCase.verifyTrue(all(isnan(analysis.installationRatio)));
            testCase.verifyTrue(all(isnan( ...
                analysis.rockerAngularGain_rad_per_m)));
        end

        function requestedZeroDefinesStaticReferenceDespiteAchievedNoise(testCase)
            [geometry,actuation] = actuationFixture();
            bump = fsd.kinematics.solveBumpSweep(geometry,[-10;0;10],"mm");
            sweep = fsd.kinematics.solveActuationSweep(actuation,bump);
            noise = 1e-13;
            sweep.results(2).sourceResult.achievedWheelTravel_m = noise;
            sweep.results(2).sourceResult.state.wheelTravel_m = noise;
            sweep.results(2).sourceAchievedWheelTravel_m = noise;
            sweep.achievedWheelTravel_m(2) = noise;
            analysis = fsd.analysis.analyzeActuationSweep(actuation,sweep);
            testCase.verifyTrue(analysis.staticReferenceAvailable);
            testCase.verifyEqual(analysis.staticReferenceIndex,2);
            testCase.verifyEqual(analysis.motionRatioMigration(2),0, ...
                "AbsTol",1e-14);
        end

        function failedRequestedZeroIsNotAStaticReference(testCase)
            [geometry,actuation] = actuationFixture( ...
                "YZ_PLANE","UPRIGHT","PUSHROD","TANGENT");
            bump = fsd.kinematics.solveBumpSweep(geometry,[2;0;-2],"mm");
            sweep = fsd.kinematics.solveActuationSweep(actuation,bump);
            analysis = fsd.analysis.analyzeActuationSweep(actuation,sweep);
            testCase.verifyFalse(analysis.staticReferenceAvailable);
            testCase.verifyTrue(isnan(analysis.staticReferenceIndex));
            testCase.verifyEqual(analysis.motionRatioStatus, ...
                "UNAVAILABLE_ACTUATION_FAILURE");
        end

        function missingStaticPointKeepsMrButNotMigration(testCase)
            [~, ~, analysis] = testCase.solveSweep([-20;-10;10;20]);
            testCase.verifyEqual(analysis.motionRatioStatus, ...
                "AVAILABLE_STATIC_REFERENCE_MISSING");
            testCase.verifyTrue(all(isfinite(analysis.damperMotionRatio)));
            testCase.verifyTrue(all(isnan(analysis.motionRatioMigration)));
            testCase.verifyFalse(analysis.staticReferenceAvailable);
        end

        function publishesDamperStrokeAndRockerRange(testCase)
            [~, sweep, analysis] = testCase.solveSweep((-20:2:20)');
            testCase.verifyEqual(analysis.minimumDamperLength_m, ...
                min(sweep.damperLength_m));
            testCase.verifyEqual(analysis.maximumDamperLength_m, ...
                max(sweep.damperLength_m));
            testCase.verifyEqual(analysis.totalRequiredStroke_m, ...
                max(sweep.damperLength_m)-min(sweep.damperLength_m), ...
                "AbsTol", 1e-15);
            testCase.verifyEqual(analysis.rockerAngularExcursion_rad, ...
                max(sweep.rockerAngle_rad)-min(sweep.rockerAngle_rad), ...
                "AbsTol", 1e-15);
            testCase.verifyEqual(analysis.maximumCompression_m, ...
                max([sweep.damperCompression_m;0]));
            testCase.verifyEqual(analysis.maximumExtension_m, ...
                max([-sweep.damperCompression_m;0]));
        end

        function pushrodPullrodAnalysisIsKinematicallyEquivalent(testCase)
            [geometry, pushrod, definition] = actuationFixture();
            bump = fsd.kinematics.solveBumpSweep( ...
                geometry, (-15:3:15)', "mm");
            pushAnalysis = fsd.analysis.analyzeActuationSweep(pushrod, ...
                fsd.kinematics.solveActuationSweep(pushrod, bump));
            definition.actuationType = "PULLROD";
            pullrod = fsd.model.createActuationGeometry( ...
                geometry, definition, "m");
            pullAnalysis = fsd.analysis.analyzeActuationSweep(pullrod, ...
                fsd.kinematics.solveActuationSweep(pullrod, bump));
            testCase.verifyNotEqual(pushAnalysis.actuationIdentity, ...
                pullAnalysis.actuationIdentity);
            testCase.verifyEqual(pushAnalysis.damperMotionRatio, ...
                pullAnalysis.damperMotionRatio, "AbsTol", 1e-14);
            testCase.verifyEqual(pushAnalysis.damperCompression_m, ...
                pullAnalysis.damperCompression_m, "AbsTol", 1e-14);
        end

        function failedSweepDoesNotPublishRangesOrRatios(testCase)
            [geometry, actuation] = actuationFixture( ...
                "YZ_PLANE", "UPRIGHT", "PUSHROD", "TANGENT");
            bump = fsd.kinematics.solveBumpSweep(geometry, [0;2;4], "mm");
            sweep = fsd.kinematics.solveActuationSweep(actuation, bump);
            analysis = fsd.analysis.analyzeActuationSweep(actuation, sweep);
            testCase.verifyEqual(string({sweep.results.status})', ...
                ["CONVERGED";"NO_ROCKER_SOLUTION";"NOT_ATTEMPTED"]);
            testCase.verifyEqual(analysis.analysisStatus, ...
                "ACTUATION_NOT_CONVERGED");
            testCase.verifyTrue(all(isnan(analysis.damperMotionRatio)));
            testCase.verifyTrue(isnan(analysis.totalRequiredStroke_m));
            testCase.verifyTrue(fsd.analysis.validateActuationSweepAnalysis( ...
                analysis, actuation, sweep));
        end

        function scalarAnalysisPreservesInvalidState(testCase)
            [geometry, actuation] = actuationFixture( ...
                "YZ_PLANE", "UPRIGHT", "PUSHROD", "TANGENT");
            source = fsd.kinematics.solveBump(geometry, 2, "mm");
            result = fsd.kinematics.solveActuation(actuation, source);
            analysis = fsd.analysis.analyzeActuation(actuation, result);
            testCase.verifyFalse(analysis.converged);
            testCase.verifyEqual(analysis.actuationStatus, ...
                "NO_ROCKER_SOLUTION");
            testCase.verifyTrue(isnan(analysis.damperCompression_m));
        end

        function validatorRejectsChangedMotionRatio(testCase)
            [actuation, sweep, analysis] = testCase.solveSweep((-10:2:10)');
            analysis.damperMotionRatio(4) = ...
                analysis.damperMotionRatio(4) + 0.1;
            analysis.installationRatio(4) = ...
                abs(analysis.damperMotionRatio(4));
            testCase.verifyError(@() ...
                fsd.analysis.validateActuationSweepAnalysis( ...
                analysis, actuation, sweep), ...
                "fsd:analysis:InvalidActuationSweepAnalysis");
        end

        function plotsFourCanonicalCurves(testCase)
            [~, ~, analysis] = testCase.solveSweep((-10:5:10)');
            fig = figure("Visible", "off");
            testCase.addTeardown(@() closeIfValid(fig));
            handles = fsd.analysis.plotActuationSweep(analysis, fig);
            testCase.verifyNumElements(handles.axes, 4);
            testCase.verifyTrue(all(isgraphics(handles.lines)));
        end
    end

    methods (Access = private)
        function [actuation, sweep, analysis] = solveSweep(~, targets_mm)
            [geometry, actuation] = actuationFixture();
            bump = fsd.kinematics.solveBumpSweep( ...
                geometry, targets_mm, "mm");
            sweep = fsd.kinematics.solveActuationSweep(actuation, bump);
            analysis = fsd.analysis.analyzeActuationSweep(actuation, sweep);
        end

        function motionRatio = analyticMotionRatio(testCase, z_m)
            % Independent implicit derivative for the analytic fixture.
            [theta, ~, ~, suspension, radial, tangent, ...
                damperChassis] = testCase.analyticState(z_m);
            dyDerivative = z_m/sqrt(0.3^2-z_m^2);
            point = radial*cos(theta)+tangent*sin(theta);
            pointDerivative = -radial*sin(theta)+tangent*cos(theta);
            suspensionDerivative = [0,dyDerivative,1];
            thetaDerivative = dot(point-suspension, ...
                suspensionDerivative) / dot(point-suspension, ...
                pointDerivative);

            damperPoint = tangent*cos(theta) - radial*sin(theta);
            damperPointDerivative = -tangent*sin(theta) - ...
                radial*cos(theta);
            damperLength = norm(damperPoint-damperChassis);
            lengthDerivativeTheta = dot( ...
                damperPoint-damperChassis, damperPointDerivative) / ...
                damperLength;
            motionRatio = -lengthDerivativeTheta*thetaDerivative;
            testCase.assertTrue(isfinite(motionRatio));
        end

        function [theta, damperLength, compression, suspension, ...
                radial, tangent, damperChassis] = analyticState(~, z_m)
            % Closed-form expected values; no production helper is called.
            dy_m = 0.3 - sqrt(0.3^2-z_m^2);
            suspension = [0, 0.15+dy_m, 0.1+z_m];
            radial = [0,0.1,0];
            tangent = [0,0,0.1];
            rodLength = sqrt(0.05^2+0.1^2);
            w = -suspension;
            A = 2*dot(w,radial);
            B = 2*dot(w,tangent);
            D = rodLength^2-dot(w,w)-dot(radial,radial);
            alpha = atan2(B,A);
            offset = acos(D/hypot(A,B));
            candidates = [alpha+offset,alpha-offset];
            [~, index] = min(abs(candidates));
            theta = candidates(index);
            damperPoint = tangent*cos(theta) - radial*sin(theta);
            damperChassis = tangent + [0.12,-0.08,0.06];
            damperLength = norm(damperPoint-damperChassis);
            staticDamperLength = norm(tangent-damperChassis);
            compression = staticDamperLength-damperLength;
        end
    end
end

function closeIfValid(figureHandle)
if isgraphics(figureHandle, "figure")
    close(figureHandle);
end
end
