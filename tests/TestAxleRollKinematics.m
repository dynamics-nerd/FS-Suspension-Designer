classdef TestAxleRollKinematics < matlab.unittest.TestCase
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
        function matchesIndependentTranslationBenchmark(testCase)
            axle = translationAxleFixture("FRONT");
            for phi = deg2rad([-5,-2,0,3,6])
                result = fsd.kinematics.solveAxleRoll(axle, phi, 0, "rad", "m");
                expectedDelta = testCase.closedFormDelta(phi);
                testCase.assertTrue(result.converged, result.failureReason);
                testCase.verifyEqual(result.wheelTravel_m, ...
                    [expectedDelta,-expectedDelta], "AbsTol", 2e-9);
            end
        end

        function positiveRollHasExpectedTravelSigns(testCase)
            result = fsd.kinematics.solveAxleRoll( ...
                translationAxleFixture(), 3, 0, "deg", "mm");
            testCase.assertTrue(result.converged, result.failureReason);
            testCase.verifyGreaterThan(result.wheelTravel_m(1), 0);
            testCase.verifyLessThan(result.wheelTravel_m(2), 0);
            testCase.verifyGreaterThan(result.wheelTravelDifferential_m, 0);
        end

        function normalBracketUsesTwoValidEndpoints(testCase)
            options = struct("InitialBracketHalfWidth_m", 0.001);
            result = fsd.kinematics.solveAxleRoll( ...
                translationAxleFixture(), 0.1, 0, "deg", "m", options);
            testCase.assertTrue(result.converged, result.failureReason);
            testCase.verifyGreaterThan(diff(result.diagnostics.bracket_m), 0);
            testCase.verifyFalse(result.diagnostics.negativeBoundaryEncountered);
            testCase.verifyFalse(result.diagnostics.positiveBoundaryEncountered);
        end

        function positiveBracketSurvivesInvalidNegativeEndpoint(testCase)
            axle = analyticAxleFixture(false);
            options = struct("InitialBracketHalfWidth_m", 0.003);
            sweep = fsd.kinematics.solveAxleRollSweep( ...
                axle, [-0.15;-0.1], 0.197541687, "deg", "m", options);
            result = sweep.results(2);
            testCase.assertTrue(result.converged, result.failureReason);
            testCase.verifyTrue(result.diagnostics.negativeBoundaryEncountered);
            testCase.verifyFalse(result.diagnostics.positiveBoundaryEncountered);
            testCase.verifyGreaterThanOrEqual( ...
                result.diagnostics.bracket_m(1), ...
                result.diagnostics.initialDelta_m);
        end

        function negativeBracketSurvivesInvalidPositiveEndpoint(testCase)
            axle = analyticAxleFixture(false);
            options = struct("InitialBracketHalfWidth_m", 0.003);
            sweep = fsd.kinematics.solveAxleRollSweep( ...
                axle, [0.15;0.1], 0.197541687, "deg", "m", options);
            result = sweep.results(2);
            testCase.assertTrue(result.converged, result.failureReason);
            testCase.verifyFalse(result.diagnostics.negativeBoundaryEncountered);
            testCase.verifyTrue(result.diagnostics.positiveBoundaryEncountered);
            testCase.verifyLessThanOrEqual( ...
                result.diagnostics.bracket_m(2), ...
                result.diagnostics.initialDelta_m);
        end

        function retainsValidSideWhenOtherHitsBoundaryAfterExpansion(testCase)
            axle = analyticAxleFixture(false);
            options = struct("InitialBracketHalfWidth_m", 0.00005);
            sweep = fsd.kinematics.solveAxleRollSweep( ...
                axle, [0.35;0.6], 0.197541687, "deg", "m", options);
            result = sweep.results(2);
            testCase.assertTrue(result.converged, result.failureReason);
            testCase.verifyGreaterThan(result.diagnostics.bracketExpansions, 1);
            testCase.verifyTrue(result.diagnostics.positiveBoundaryEncountered);
            testCase.verifyFalse(result.diagnostics.negativeBoundaryEncountered);
            testCase.verifyGreaterThan( ...
                result.diagnostics.positiveBoundaryExpansion, 1);
        end

        function nearLimitRegressionUsesReachableLocalDomain(testCase)
            axle = analyticAxleFixture(false);
            result = fsd.kinematics.solveAxleRoll( ...
                axle, 0.1, 0.197541687, "deg", "m");
            expectedDelta_m = 0.000526305367;
            testCase.assertTrue(result.converged, result.failureReason);
            testCase.verifyEqual(result.wheelTravelDifferential_m/2, ...
                expectedDelta_m, "AbsTol", 5e-9);
            testCase.verifyTrue(result.axleTravelResult.leftConverged);
            testCase.verifyTrue(result.axleTravelResult.rightConverged);
            testCase.verifyLessThanOrEqual(abs(result.closureResidual_m), 1e-9);
            testCase.verifyTrue(result.diagnostics.negativeBoundaryEncountered);
            testCase.verifyTrue(result.diagnostics.positiveBoundaryEncountered);
        end

        function insufficientKinematicDomainIsExplicit(testCase)
            options = struct( ...
                "InitialBracketHalfWidth_m", 0.005, ...
                "BoundaryRefinementTolerance_m", 0.01);
            result = fsd.kinematics.solveAxleRoll( ...
                analyticAxleFixture(false), 0.1, 0.197541687, ...
                "deg", "m", options);
            testCase.verifyFalse(result.converged);
            testCase.verifyEqual(result.status, "KINEMATIC_NONCONVERGENCE");
            testCase.verifyEqual(result.diagnostics.validEvaluationCount, 1);
        end

        function rootAtCenterAvoidsExpansionAndFzero(testCase)
            result = fsd.kinematics.solveAxleRoll( ...
                analyticAxleFixture(false), 0, 0, "deg", "m");
            testCase.assertTrue(result.converged, result.failureReason);
            testCase.verifyEqual(result.diagnostics.bracketExpansions, 0);
            testCase.verifyEqual(result.diagnostics.rootFunctionEvaluations, 0);
            testCase.verifyEqual(result.diagnostics.kinematicEvaluations, 1);
        end

        function closureResidualUsesActualContacts(testCase)
            axle = analyticAxleFixture(false);
            cases = [2,0; -2,0; 1.5,12; -1.5,-8];
            for target = cases.'
                result = fsd.kinematics.solveAxleRoll( ...
                    axle, target(1), target(2), "deg", "mm");
                testCase.assertTrue(result.converged, result.failureReason);
                phi = deg2rad(target(1));
                difference = result.rightGeometricContact.point_m(2:3) - ...
                    result.leftGeometricContact.point_m(2:3);
                independent = [sin(phi),cos(phi)] * difference.';
                testCase.verifyEqual(independent, 0, "AbsTol", 2e-9);
                testCase.verifyEqual(result.closureResidual_m, independent, ...
                    "AbsTol", 2e-12);
            end
        end

        function asymmetricGeometryClosesWithoutMirrorAssumptions(testCase)
            axle = analyticAxleFixture(true);
            result = fsd.kinematics.solveAxleRoll(axle, 1.5, 7, "deg", "mm");
            testCase.assertTrue(result.converged, result.failureReason);
            phi = deg2rad(1.5);
            chord = result.rightGeometricContact.point_m(2:3) - ...
                result.leftGeometricContact.point_m(2:3);
            testCase.verifyEqual([sin(phi),cos(phi)]*chord.', 0, ...
                "AbsTol", 2e-9);
            testCase.verifyEqual(mean(result.wheelTravel_m), 0.007, ...
                "AbsTol", 2e-12);
            testCase.verifyGreaterThan(abs( ...
                abs(result.leftGeometricContact.point_m(3)) - ...
                abs(result.rightGeometricContact.point_m(3))), 1e-7);
        end

        function angleUnitsAreEquivalent(testCase)
            axle = analyticAxleFixture(false);
            degrees = fsd.kinematics.solveAxleRoll(axle, 2, 5, "deg", "mm");
            radians = fsd.kinematics.solveAxleRoll( ...
                axle, deg2rad(2), 0.005, "rad", "m");
            testCase.verifyEqual(degrees.wheelTravel_m, radians.wheelTravel_m, ...
                "AbsTol", 2e-12);
        end

        function orderedSweepRoundTripsAtZeroHeave(testCase)
            axle = analyticAxleFixture(false);
            sweep = fsd.kinematics.solveAxleRollSweep( ...
                axle, [0;2;0;-2;0], 0, "deg", "mm");
            testCase.assertTrue(sweep.allConverged);
            testCase.verifyEqual(sweep.requestedBodyRollAngle_rad, ...
                deg2rad([0;2;0;-2;0]), "AbsTol", 1e-15);
            testCase.verifyEqual(sweep.results(3).axleTravelResult.leftResult. ...
                state.xyz_m, sweep.results(1).axleTravelResult.leftResult. ...
                state.xyz_m, "AbsTol", 2e-8);
            testCase.verifyEqual(sweep.results(5).axleTravelResult.rightResult. ...
                state.xyz_m, sweep.results(1).axleTravelResult.rightResult. ...
                state.xyz_m, "AbsTol", 2e-8);
        end

        function roundTripsAtNonzeroHeave(testCase)
            axle = analyticAxleFixture(false);
            sweep = fsd.kinematics.solveAxleRollSweep( ...
                axle, [0;2;0], 10, "deg", "mm");
            testCase.assertTrue(sweep.allConverged);
            testCase.verifyEqual(sweep.results(3).wheelTravel_m, [0.01,0.01], ...
                "AbsTol", 2e-9);
            testCase.verifyEqual(sweep.results(3).axleTravelResult.leftResult. ...
                state.xyz_m, sweep.results(1).axleTravelResult.leftResult. ...
                state.xyz_m, "AbsTol", 2e-8);
        end

        function mirroredRollStatesHaveExpectedTravelParity(testCase)
            axle = analyticAxleFixture(false);
            positive = fsd.kinematics.solveAxleRoll(axle, 2, 0, "deg", "mm");
            negative = fsd.kinematics.solveAxleRoll(axle, -2, 0, "deg", "mm");
            testCase.assertTrue(positive.converged && negative.converged);
            testCase.verifyEqual(positive.wheelTravel_m, ...
                fliplr(negative.wheelTravel_m), "AbsTol", 2e-9);
            testCase.verifyEqual(positive.wheelTravel_m, ...
                -negative.wheelTravel_m, "AbsTol", 2e-9);
        end

        function supportsRearAxle(testCase)
            result = fsd.kinematics.solveAxleRoll( ...
                translationAxleFixture("REAR"), -3, 4, "deg", "mm");
            testCase.verifyTrue(result.converged, result.failureReason);
            testCase.verifyEqual(result.axleIdentity.axleId, "REAR");
            testCase.verifyEqual(mean(result.wheelTravel_m), 0.004, ...
                "AbsTol", 2e-12);
        end

        function impossibleHeaveFailsWithoutPublishingState(testCase)
            result = fsd.kinematics.solveAxleRoll( ...
                analyticAxleFixture(false), 2, 500, "deg", "mm");
            testCase.verifyFalse(result.converged);
            testCase.verifyEqual(result.status, "KINEMATIC_NONCONVERGENCE");
            testCase.verifyTrue(all(isnan(result.wheelTravel_m)));
            testCase.verifyTrue(isempty(fieldnames(result.axleTravelResult)));
            testCase.verifyEqual(result.diagnostics.stage, "HEAVE");
        end

        function unbracketedRollIsExplicit(testCase)
            options = struct("InitialBracketHalfWidth_m", 1e-6, ...
                "MaxBracketExpansions", 1);
            result = fsd.kinematics.solveAxleRoll( ...
                analyticAxleFixture(false), 4, 0, "deg", "mm", options);
            testCase.verifyFalse(result.converged);
            testCase.verifyEqual(result.status, "ROOT_NOT_BRACKETED");
            testCase.verifyGreaterThan(result.diagnostics.kinematicEvaluations, 0);
        end

        function validatesIdentityAndTargets(testCase)
            axle = analyticAxleFixture(false);
            result = fsd.kinematics.solveAxleRoll(axle, 2, 0, "deg", "mm");
            result.requestedBodyRollAngle_rad = result.requestedBodyRollAngle_rad + 1e-3;
            testCase.verifyError(@() ...
                fsd.kinematics.validateAxleRollResult(result), ...
                "fsd:kinematics:InvalidAxleRollResult");
        end

        function integratesTravelWithExistingSteeringSolver(testCase)
            axle = analyticAxleFixture(false);
            roll = fsd.kinematics.solveAxleRoll(axle, 2, 0, "deg", "mm");
            steering = fsd.model.createSteeringSystem(axle, 1.6, "m");
            steered = fsd.kinematics.solveSteering( ...
                steering, 0.005, roll.wheelTravel_m, "m");
            testCase.verifyTrue(steered.converged, steered.failureReason);
            testCase.verifyTrue( ...
                fsd.kinematics.validateSteeringResult(steered, steering));
            testCase.verifyEqual(steered.requestedWheelTravel_m, ...
                roll.wheelTravel_m, "AbsTol", 1e-15);
        end
    end

    methods (Static, Access = private)
        function delta_m = closedFormDelta(phi_rad)
            radius_m = 0.30;
            halfStaticContactTrack_m = 0.65;
            offset_m = halfStaticContactTrack_m - radius_m;
            tangent = tan(phi_rad);
            delta_m = tangent * (offset_m + sqrt(radius_m^2 + ...
                tangent^2 * (radius_m^2-offset_m^2))) / ...
                (1+tangent^2);
        end
    end
end
