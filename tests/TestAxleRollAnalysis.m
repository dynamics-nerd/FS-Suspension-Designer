classdef TestAxleRollAnalysis < matlab.unittest.TestCase
    properties
        OriginalPath
    end

    methods (TestMethodSetup)
        function addSourceToPath(testCase)
            root = fileparts(fileparts(mfilename("fullpath")));
            testCase.OriginalPath = path;
            testCase.addTeardown(@() path(testCase.OriginalPath));
            addpath(fullfile(root, "src"));
        end
    end

    methods (Test)
        function publishesRequiredRollMetrics(testCase)
            axle = analyticAxleFixture(false);
            result = fsd.kinematics.solveAxleRoll(axle, 2, 5, "deg", "mm");
            analysis = fsd.analysis.analyzeAxleRoll(axle, result);
            testCase.verifyTrue(fsd.analysis.validateAxleRollAnalysis(analysis));
            testCase.verifyTrue(all(isfinite(analysis.chassisCamber_rad)));
            testCase.verifyTrue(all(isfinite(analysis.roadCamber_rad)));
            testCase.verifyTrue(all(isfinite(analysis.toe_rad)));
            testCase.verifyGreaterThan(analysis.wheelCenterTrack_m, 0);
            testCase.verifyGreaterThan(analysis.geometricContactTrack_m, 0);
            testCase.verifyEqual(analysis.wheelTravelDifferential_m, ...
                analysis.wheelTravel_m(1)-analysis.wheelTravel_m(2), ...
                "AbsTol", 1e-15);
        end

        function horizontalRoadHeightMatchesHistoricalMeaning(testCase)
            axle = analyticAxleFixture(false);
            result = fsd.kinematics.solveAxleRoll(axle, 0, 0, "deg", "mm");
            analysis = fsd.analysis.analyzeAxleRoll(axle, result);
            historical = fsd.analysis.rollCenter(axle);
            testCase.verifyEqual(analysis.rollCenterRoadHeight_m, ...
                historical.rollCenterHeight_m, "AbsTol", 2e-12);
            testCase.verifyEqual(analysis.rollCenterHeight_m, ...
                historical.rollCenterHeight_m, "AbsTol", 2e-12);
        end

        function inclinedRoadHeightUsesSignedPerpendicularDistance(testCase)
            axle = analyticAxleFixture(false);
            result = fsd.kinematics.solveAxleRoll(axle, 3, 0, "deg", "mm");
            analysis = fsd.analysis.analyzeAxleRoll(axle, result);
            coefficients = analysis.roadLine.coefficients;
            expected = coefficients(1)*analysis.rollCenterY_m + ...
                coefficients(2)*analysis.rollCenterZ_m + coefficients(3);
            testCase.verifyEqual(analysis.rollCenterRoadHeight_m, expected, ...
                "AbsTol", 2e-14);
            testCase.verifyEqual(analysis.rollCenterHeightStatus, ...
                "CONTACT_LEVEL_MISMATCH");
            testCase.verifyTrue(isnan(analysis.rollCenterHeight_m));
        end

        function symmetricGeometryObeysRollParity(testCase)
            axle = analyticAxleFixture(false);
            positive = fsd.analysis.analyzeAxleRoll(axle, ...
                fsd.kinematics.solveAxleRoll(axle, 2, 0, "deg", "mm"));
            negative = fsd.analysis.analyzeAxleRoll(axle, ...
                fsd.kinematics.solveAxleRoll(axle, -2, 0, "deg", "mm"));
            testCase.verifyEqual(positive.chassisCamber_rad, ...
                -negative.chassisCamber_rad, "AbsTol", 1e-7);
            testCase.verifyEqual(positive.roadCamber_rad, ...
                -negative.roadCamber_rad, "AbsTol", 1e-7);
            testCase.verifyEqual(positive.toe_rad, ...
                fliplr(negative.toe_rad), "AbsTol", 2e-8);
            testCase.verifyEqual(positive.rollCenterY_m, ...
                -negative.rollCenterY_m, "AbsTol", 2e-8);
            testCase.verifyEqual(positive.rollCenterZ_m, ...
                negative.rollCenterZ_m, "AbsTol", 2e-8);
            testCase.verifyEqual(positive.rollCenterRoadHeight_m, ...
                negative.rollCenterRoadHeight_m, "AbsTol", 2e-8);
            testCase.verifyEqual(positive.wheelCenterTrack_m, ...
                negative.wheelCenterTrack_m, "AbsTol", 2e-8);
            testCase.verifyEqual(positive.geometricContactTrack_m, ...
                negative.geometricContactTrack_m, "AbsTol", 2e-8);
        end

        function sweepAggregatesFullyConvergedMetrics(testCase)
            axle = analyticAxleFixture(false);
            sweep = fsd.kinematics.solveAxleRollSweep( ...
                axle, (-2:1:2)', 0, "deg", "mm");
            analysis = fsd.analysis.analyzeAxleRollSweep(axle, sweep);
            testCase.verifyTrue( ...
                fsd.analysis.validateAxleRollSweepAnalysis(analysis));
            testCase.verifySize(analysis.chassisCamber_rad, [5,2]);
            testCase.verifySize(analysis.roadCamber_rad, [5,2]);
            testCase.verifySize(analysis.wheelTravel_m, [5,2]);
            testCase.verifyTrue(all(isfinite(analysis.rollCenterRoadHeight_m)));
        end

        function failedSweepPreservesKinematicAndAnalysisStatuses(testCase)
            axle = analyticAxleFixture(false);
            options = struct("InitialBracketHalfWidth_m", 1e-6, ...
                "MaxBracketExpansions", 1);
            sweep = fsd.kinematics.solveAxleRollSweep( ...
                axle, [0;4;0], 0, "deg", "mm", options);
            analysis = fsd.analysis.analyzeAxleRollSweep(axle, sweep);
            testCase.verifyEqual(analysis.kinematicStatus, ...
                ["CONVERGED";"ROOT_NOT_BRACKETED";"NOT_ATTEMPTED"]);
            testCase.verifyEqual(analysis.analysisStatus, ...
                ["CONVERGED";"KINEMATICS_NOT_CONVERGED"; ...
                "KINEMATICS_NOT_CONVERGED"]);
            testCase.verifyTrue(all(isfinite(analysis.chassisCamber_rad(1,:))));
            numericFailures = [analysis.wheelTravel_m(2:3,:), ...
                analysis.wheelTravelDifferential_m(2:3), ...
                analysis.chassisCamber_rad(2:3,:), ...
                analysis.roadCamber_rad(2:3,:), analysis.toe_rad(2:3,:), ...
                analysis.leftInstantCenterY_m(2:3), ...
                analysis.leftInstantCenterZ_m(2:3), ...
                analysis.rightInstantCenterY_m(2:3), ...
                analysis.rightInstantCenterZ_m(2:3), ...
                analysis.rollCenterY_m(2:3), analysis.rollCenterZ_m(2:3), ...
                analysis.rollCenterRoadHeight_m(2:3), ...
                analysis.wheelCenterTrack_m(2:3), ...
                analysis.geometricContactTrack_m(2:3), ...
                analysis.wheelCenterTrackChange_m(2:3), ...
                analysis.geometricContactTrackChange_m(2:3)];
            testCase.verifyTrue(all(isnan(numericFailures), "all"));
            testCase.verifyTrue( ...
                fsd.analysis.validateAxleRollSweepAnalysis(analysis));
        end

        function failedKinematicsPublishesOnlyNaNMetrics(testCase)
            axle = analyticAxleFixture(false);
            result = fsd.kinematics.solveAxleRoll(axle, 2, 500, "deg", "mm");
            analysis = fsd.analysis.analyzeAxleRoll(axle, result);
            testCase.verifyFalse(analysis.converged);
            testCase.verifyEqual(analysis.status, "KINEMATICS_NOT_CONVERGED");
            testCase.verifyTrue(all(isnan(analysis.chassisCamber_rad)));
            testCase.verifyTrue(isnan(analysis.rollCenterRoadHeight_m));
            testCase.verifyTrue(isnan(analysis.geometricContactTrack_m));
        end

        function rejectsResultFromDifferentAxle(testCase)
            first = analyticAxleFixture(false);
            second = analyticAxleFixture(true);
            result = fsd.kinematics.solveAxleRoll(first, 1, 0, "deg", "mm");
            testCase.verifyError(@() fsd.analysis.analyzeAxleRoll( ...
                second, result), "fsd:analysis:AxleGeometryMismatch");
        end

        function rejectsManipulatedAnalysis(testCase)
            axle = analyticAxleFixture(false);
            result = fsd.kinematics.solveAxleRoll(axle, 1, 0, "deg", "mm");
            analysis = fsd.analysis.analyzeAxleRoll(axle, result);
            analysis.wheelTravelDifferential_m = ...
                analysis.wheelTravelDifferential_m + 0.01;
            testCase.verifyError(@() ...
                fsd.analysis.validateAxleRollAnalysis(analysis), ...
                "fsd:analysis:InvalidAxleRollAnalysis");
        end

        function plotsFrontViewAndSweep(testCase)
            axle = analyticAxleFixture(false);
            result = fsd.kinematics.solveAxleRoll(axle, 2, 0, "deg", "mm");
            state = fsd.analysis.analyzeAxleRoll(axle, result);
            sweep = fsd.kinematics.solveAxleRollSweep( ...
                axle, (-2:1:2)', 0, "deg", "mm");
            curves = fsd.analysis.analyzeAxleRollSweep(axle, sweep);
            frontFigure = figure("Visible", "off");
            curveFigure = figure("Visible", "off");
            testCase.addTeardown(@() closeIfValid(frontFigure));
            testCase.addTeardown(@() closeIfValid(curveFigure));
            front = fsd.analysis.plotAxleRollFrontView( ...
                state, axes(frontFigure));
            plots = fsd.analysis.plotAxleRollSweep(curves, curveFigure);
            testCase.verifyTrue(isgraphics(front.road));
            testCase.verifyEqual(numel(front.wheels), 2);
            testCase.verifyTrue(isgraphics(plots.camberAxes, "axes"));
            testCase.verifyEqual(numel(findobj(curveFigure, "Type", "axes")), 4);
        end
    end
end

function closeIfValid(figureHandle)
if isgraphics(figureHandle, "figure")
    close(figureHandle);
end
end
