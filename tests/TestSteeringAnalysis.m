classdef TestSteeringAnalysis < matlab.unittest.TestCase
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
        function roadWheelHeadingUsesOneGlobalSign(testCase)
            angle = 7 * pi / 180;
            [straightLeft, zeroLeft] = fsd.analysis.roadWheelHeading( ...
                [0, -1, 0], "FL");
            [straightRight, zeroRight] = fsd.analysis.roadWheelHeading( ...
                [0, 1, 0], "FR");
            [rightTurnLeft, angleLeft] = fsd.analysis.roadWheelHeading( ...
                [-sin(angle), -cos(angle), 0], "FL");
            [rightTurnRight, angleRight] = fsd.analysis.roadWheelHeading( ...
                [sin(angle), cos(angle), 0], "FR");
            testCase.verifyEqual(straightLeft, [-1, 0, 0]);
            testCase.verifyEqual(straightRight, [-1, 0, 0]);
            testCase.verifyEqual([zeroLeft, zeroRight], [0, 0]);
            testCase.verifyGreaterThan(rightTurnLeft(2), 0);
            testCase.verifyGreaterThan(rightTurnRight(2), 0);
            testCase.verifyEqual([angleLeft, angleRight], [angle, angle], ...
                "AbsTol", 1e-14);
        end

        function angleWrappingCrossesPiContinuously(testCase)
            delta = fsd.geometry.wrapAngle( ...
                (-pi + 0.01) - (pi - 0.01));
            testCase.verifyEqual(delta, 0.02, "AbsTol", 1e-14);
        end

        function steeringAxisIntersectionReportsParallel(testCase)
            intersection = ...
                fsd.geometry.intersectSteeringAxisWithHorizontalPlane( ...
                [0, 0, 0.1], [1, 0, 0.1], 0);
            testCase.verifyEqual(intersection.status, "PARALLEL");
            testCase.verifyTrue(all(isnan(intersection.point_m)));
        end

        function scrubAndTrailHaveKnownSigns(testCase)
            left = fsd.analysis.scrubAndMechanicalTrail( ...
                [0, -0.5, 0.1], [0.04, -0.4, 0.3], ...
                [0, -0.6, 0], "FL");
            right = fsd.analysis.scrubAndMechanicalTrail( ...
                [0, 0.5, 0.1], [0.04, 0.4, 0.3], ...
                [0, 0.6, 0], "FR");
            testCase.verifyEqual(left.scrubRadius_m, 0.05, ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(right.scrubRadius_m, 0.05, ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(left.mechanicalTrail_m, 0.02, ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(right.mechanicalTrail_m, 0.02, ...
                "AbsTol", 1e-14);
            negative = fsd.analysis.scrubAndMechanicalTrail( ...
                [0, -0.5, 0.1], [0.04, -0.4, 0.3], ...
                [-0.04, -0.5, 0], "FL");
            testCase.verifyLessThan(negative.scrubRadius_m, 0);
            testCase.verifyLessThan(negative.mechanicalTrail_m, 0);
            zero = fsd.analysis.scrubAndMechanicalTrail( ...
                [0, -0.5, 0.1], [0, -0.4, 0.3], ...
                [0, -0.55, 0], "FL");
            testCase.verifyEqual(zero.scrubRadius_m, 0, ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(zero.mechanicalTrail_m, 0, ...
                "AbsTol", 1e-14);
        end

        function classicAckermannHasCommonIcr(testCase)
            rearX_m = 1.6;
            icrY_m = 3.0;
            leftContact = [0, -0.6, 0];
            rightContact = [0, 0.6, 0];
            leftHeading = testCase.tangent(leftContact, [rearX_m, icrY_m]);
            rightHeading = testCase.tangent(rightContact, [rearX_m, icrY_m]);
            leftAngle = atan2(leftHeading(2), -leftHeading(1));
            rightAngle = atan2(rightHeading(2), -rightHeading(1));
            ackermann = fsd.analysis.ackermannGeometry( ...
                leftContact, leftHeading, rightContact, rightHeading, ...
                rearX_m, leftAngle, rightAngle);
            testCase.verifyEqual(ackermann.status, "VALID");
            testCase.verifyEqual(ackermann.leftIcr.y_m, icrY_m, ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(ackermann.rightIcr.y_m, icrY_m, ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(ackermann.icrMismatch_m, 0, ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(ackermann.ackermannAngleError_rad, 0, ...
                "AbsTol", 1e-14);
        end

        function parallelSteeringIsNotIdealAckermann(testCase)
            angle = 12 * pi / 180;
            heading = [-cos(angle), sin(angle), 0];
            ackermann = fsd.analysis.ackermannGeometry( ...
                [0, -0.6, 0], heading, [0, 0.6, 0], heading, ...
                1.6, angle, angle);
            testCase.verifyEqual(ackermann.status, "VALID");
            testCase.verifyGreaterThan(abs(ackermann.icrMismatch_m), 1);
            testCase.verifyGreaterThan( ...
                abs(ackermann.ackermannAngleError_rad), 1e-3);
        end

        function ackermannErrorSignIsActualMinusIdeal(testCase)
            rearX_m = 1.6;
            icrY_m = 3.0;
            leftContact = [0, -0.6, 0];
            rightContact = [0, 0.6, 0];
            idealLeft = testCase.tangent(leftContact, [rearX_m, icrY_m]);
            inner = testCase.tangent(rightContact, [rearX_m, icrY_m]);
            idealAngle = atan2(idealLeft(2), -idealLeft(1));
            innerAngle = atan2(inner(2), -inner(1));
            high = idealAngle + pi/180;
            low = idealAngle - pi/180;
            over = fsd.analysis.ackermannGeometry(leftContact, ...
                [-cos(high), sin(high), 0], rightContact, inner, ...
                rearX_m, high, innerAngle);
            under = fsd.analysis.ackermannGeometry(leftContact, ...
                [-cos(low), sin(low), 0], rightContact, inner, ...
                rearX_m, low, innerAngle);
            testCase.verifyGreaterThan(over.ackermannAngleError_rad, 0);
            testCase.verifyLessThan(under.ackermannAngleError_rad, 0);
        end

        function staticToeAtZeroRackIsNearStraight(testCase)
            toe = 2 * pi / 180;
            leftHeading = [-cos(toe), sin(toe), 0];
            rightHeading = [-cos(toe), -sin(toe), 0];
            ackermann = fsd.analysis.ackermannGeometry( ...
                [0, -0.6, 0], leftHeading, [0, 0.6, 0], rightHeading, ...
                1.6, 0, 0);
            testCase.verifyEqual(ackermann.status, "NEAR_STRAIGHT");
            testCase.verifyTrue(isnan(ackermann.ackermannAngleError_rad));
        end

        function nearStraightIcrIsProjectivelyInfinite(testCase)
            heading = [-1, 0, 0];
            ackermann = fsd.analysis.ackermannGeometry( ...
                [0, -0.6, 0], heading, [0, 0.6, 0], heading, ...
                1.6, 0, 0);
            testCase.verifyEqual(ackermann.leftIcr.status, "INFINITE");
            testCase.verifyEqual(ackermann.leftIcr.homogeneousPoint, [1, 0]);
            testCase.verifyEqual(ackermann.conditioning, 0);
        end

        function ackermannSupportsWheelStagger(testCase)
            rearX_m = 1.6;
            icrY_m = -2.7;
            leftContact = [0.04, -0.6, 0];
            rightContact = [-0.03, 0.6, 0];
            leftHeading = testCase.tangent(leftContact, [rearX_m, icrY_m]);
            rightHeading = testCase.tangent(rightContact, [rearX_m, icrY_m]);
            leftAngle = atan2(leftHeading(2), -leftHeading(1));
            rightAngle = atan2(rightHeading(2), -rightHeading(1));
            ackermann = fsd.analysis.ackermannGeometry( ...
                leftContact, leftHeading, rightContact, rightHeading, ...
                rearX_m, leftAngle, rightAngle);
            testCase.verifyEqual(ackermann.leftIcr.y_m, icrY_m, ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(ackermann.rightIcr.y_m, icrY_m, ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(ackermann.ackermannAngleError_rad, 0, ...
                "AbsTol", 1e-14);
        end

        function integratedBumpSteeringPublishesDistinctAngles(testCase)
            steering = testCase.system();
            result = fsd.kinematics.solveSteering( ...
                steering, 6, [12, 8], "mm");
            analysis = fsd.analysis.analyzeSteering(steering, result);
            testCase.assertTrue(result.converged, result.failureReason);
            testCase.verifyEqual(analysis.left.toe_rad - ...
                analysis.left.staticToe_rad, analysis.left.bumpSteer_rad, ...
                "AbsTol", 1e-14);
            baselineAngle = fsd.analysis.roadWheelHeading( ...
                result.leftResult.rackZeroKinematicResult.wheelAxis, "FL");
            testCase.verifyNotEqual(analysis.left.rackInducedSteer_rad, ...
                analysis.left.steerDeflectionFromStatic_rad);
            testCase.verifyTrue(all(isfinite( ...
                analysis.left.geometricContact.point_m)));
            testCase.verifyTrue(isfinite(analysis.left.scrubRadius_m));
            testCase.verifyTrue(isfinite(analysis.left.mechanicalTrail_m));
            testCase.verifyEqual(norm(baselineAngle), 1, "AbsTol", 1e-14);
        end

        function mirroredRackInputsProduceMirroredTurns(testCase)
            steering = testCase.system();
            positive = fsd.analysis.analyzeSteering(steering, ...
                fsd.kinematics.solveSteering(steering, 6, 0, "mm"));
            negative = fsd.analysis.analyzeSteering(steering, ...
                fsd.kinematics.solveSteering(steering, -6, 0, "mm"));
            testCase.verifyEqual(positive.left.roadWheelAngle_rad, ...
                -negative.right.roadWheelAngle_rad, "AbsTol", 2e-8);
            testCase.verifyEqual(positive.right.roadWheelAngle_rad, ...
                -negative.left.roadWheelAngle_rad, "AbsTol", 2e-8);
            testCase.verifyEqual(positive.left.scrubRadius_m, ...
                negative.right.scrubRadius_m, "AbsTol", 2e-8);
            testCase.verifyEqual(positive.ackermann.ackermannAngleError_rad, ...
                -negative.ackermann.ackermannAngleError_rad, ...
                "AbsTol", 2e-8);
        end

        function zeroRackPreservesExistingBumpSteerCurve(testCase)
            steering = testCase.system();
            travel_mm = [-15; 0; 15];
            for index = 1:numel(travel_mm)
                result = fsd.kinematics.solveSteering( ...
                    steering, 0, travel_mm(index), "mm");
                steeringAnalysis = fsd.analysis.analyzeSteering( ...
                    steering, result);
                leftGeometry = steering.frontAxleGeometry.leftGeometry;
                legacyResult = fsd.kinematics.solveBump( ...
                    leftGeometry, travel_mm(index), "mm");
                legacyAnalysis = fsd.analysis.analyzeCornerState( ...
                    leftGeometry, legacyResult);
                staticToe = fsd.analysis.toeFromWheelAxis( ...
                    leftGeometry.wheel.wheelAxis, "FL");
                testCase.verifyEqual(steeringAnalysis.left.toe_rad, ...
                    legacyAnalysis.toe_rad, "AbsTol", 2e-12);
                testCase.verifyEqual(steeringAnalysis.left.bumpSteer_rad, ...
                    fsd.geometry.wrapAngle(legacyAnalysis.toe_rad - ...
                    staticToe), "AbsTol", 2e-12);
                testCase.verifyEqual( ...
                    steeringAnalysis.left.rackInducedSteer_rad, 0, ...
                    "AbsTol", 2e-12);
            end
        end

        function failedSteeringDoesNotPublishAnalysis(testCase)
            steering = testCase.system();
            result = fsd.kinematics.solveSteering( ...
                steering, 500, 0, "mm");
            analysis = fsd.analysis.analyzeSteering(steering, result);
            testCase.verifyFalse(result.converged);
            testCase.verifyTrue(isnan(analysis.left.roadWheelAngle_rad));
            testCase.verifyTrue(isnan(analysis.left.scrubRadius_m));
            testCase.verifyEqual(analysis.ackermann.status, ...
                "KINEMATICS_NOT_CONVERGED");
        end

        function unilateralFailureInvalidatesBothAnalysisSides(testCase)
            cases = {"FR", 10; "FL", -10};
            for index = 1:size(cases, 1)
                failingCorner = cases{index, 1};
                rackTravel_mm = cases{index, 2};
                steering = testCase.unilateralFailureSystem(failingCorner);
                result = fsd.kinematics.solveSteering( ...
                    steering, rackTravel_mm, 0, "mm");
                analysis = fsd.analysis.analyzeSteering(steering, result);

                testCase.verifyFalse(result.converged);
                if failingCorner == "FR"
                    testCase.verifyTrue(result.leftConverged);
                    testCase.verifyFalse(result.rightConverged);
                else
                    testCase.verifyFalse(result.leftConverged);
                    testCase.verifyTrue(result.rightConverged);
                end
                testCase.verifyFalse(analysis.converged);
                testCase.verifyEqual(analysis.left.status, ...
                    "KINEMATICS_NOT_CONVERGED");
                testCase.verifyEqual(analysis.right.status, ...
                    "KINEMATICS_NOT_CONVERGED");
                testCase.verifyTrue(all(isnan([ ...
                    analysis.left.roadWheelAngle_rad, ...
                    analysis.left.rackInducedSteer_rad, ...
                    analysis.left.toe_rad, analysis.left.scrubRadius_m, ...
                    analysis.left.mechanicalTrail_m])));
                testCase.verifyTrue(all(isnan([ ...
                    analysis.right.roadWheelAngle_rad, ...
                    analysis.right.rackInducedSteer_rad, ...
                    analysis.right.toe_rad, analysis.right.scrubRadius_m, ...
                    analysis.right.mechanicalTrail_m])));
                testCase.verifyTrue(all(isnan( ...
                    analysis.left.geometricContact.point_m)));
                testCase.verifyTrue(all(isnan( ...
                    analysis.right.geometricContact.point_m)));
                testCase.verifyEqual(analysis.ackermann.status, ...
                    "KINEMATICS_NOT_CONVERGED");
                testCase.verifyEqual(analysis.left.kinematicConverged, ...
                    result.leftConverged);
                testCase.verifyEqual(analysis.right.kinematicConverged, ...
                    result.rightConverged);
                testCase.verifyEqual(analysis.left.kinematicStatus, ...
                    string(result.leftResult.status));
                testCase.verifyEqual(analysis.right.kinematicStatus, ...
                    string(result.rightResult.status));
                testCase.verifyEqual( ...
                    analysis.left.kinematicFailureReason, ...
                    string(result.leftResult.failureReason));
                testCase.verifyEqual( ...
                    analysis.right.kinematicFailureReason, ...
                    string(result.rightResult.failureReason));
                testCase.verifyEqual(analysis.left.solverDiagnostics, ...
                    result.leftResult.diagnostics);
                testCase.verifyEqual(analysis.right.solverDiagnostics, ...
                    result.rightResult.diagnostics);
            end
        end

        function rackSweepUnilateralFailureLeavesNoPartialCurves(testCase)
            steering = testCase.unilateralFailureSystem("FR");
            sweep = fsd.kinematics.solveRackSweep( ...
                steering, [0; 2; 4; 6; 8; 10], 0, "mm");
            analysis = fsd.analysis.analyzeRackSweep(steering, sweep);

            testCase.verifyTrue(all(sweep.converged(1:4)));
            testCase.verifyTrue(sweep.results(5).leftConverged);
            testCase.verifyFalse(sweep.results(5).rightConverged);
            testCase.verifyEqual(sweep.results(5).rightResult.status, ...
                "NO_CONVERGENCE");
            testCase.verifyEqual(sweep.results(6).rightResult.status, ...
                "NOT_ATTEMPTED");
            fields = ["roadWheelAngleLeft_rad", ...
                "roadWheelAngleRight_rad", "steerDeflectionLeft_rad", ...
                "steerDeflectionRight_rad", "rackInducedSteerLeft_rad", ...
                "rackInducedSteerRight_rad", "toeLeft_rad", ...
                "toeRight_rad", "scrubRadiusLeft_m", ...
                "scrubRadiusRight_m", "mechanicalTrailLeft_m", ...
                "mechanicalTrailRight_m", "ackermannAngleError_rad"];
            for field = fields
                testCase.verifyTrue(all(isnan(analysis.(field)(5:6))), ...
                    "Expected NaN bilateral metrics for " + field);
            end
            testCase.verifyEqual(analysis.states(5).left.status, ...
                "KINEMATICS_NOT_CONVERGED");
            testCase.verifyTrue( ...
                analysis.states(5).left.kinematicConverged);
            testCase.verifyFalse( ...
                analysis.states(5).right.kinematicConverged);
        end

        function rackSweepRejectsTamperingBeforePrivateCore(testCase)
            steering = testCase.system();
            sweep = fsd.kinematics.solveRackSweep( ...
                steering, [0; 5], 0, "mm");
            sweep.results(2).leftResult.state.ubj_m(1) = ...
                sweep.results(2).leftResult.state.ubj_m(1) + 1e-3;
            testCase.verifyError(@() fsd.analysis.analyzeRackSweep( ...
                steering, sweep), ...
                "fsd:kinematics:InvalidSuspensionState");
        end

        function sweepAnalysisAndPlotsAreComplete(testCase)
            steering = testCase.system();
            sweep = fsd.kinematics.solveRackSweep( ...
                steering, (-10:5:10)', 0, "mm");
            analysis = fsd.analysis.analyzeRackSweep(steering, sweep);
            testCase.verifyEqual(numel(analysis.roadWheelAngleLeft_rad), 5);
            testCase.verifyEqual(analysis.ackermannStatus(3), ...
                "NEAR_STRAIGHT");
            figureHandle = figure("Visible", "off");
            testCase.addTeardown(@() closeIfValid(figureHandle));
            handles = fsd.analysis.plotSteeringSweep(analysis, figureHandle);
            testCase.verifyEqual(numel(handles.axes), 5);
            testCase.verifyTrue(all(isgraphics(handles.axes)));
        end
    end

    methods (Static, Access = private)
        function steering = system()
            steering = fsd.model.createSteeringSystem( ...
                analyticAxleFixture(false), 1.6, "m");
        end

        function steering = unilateralFailureSystem(failingCorner)
            axle = analyticAxleFixture(false);
            if failingCorner == "FR"
                geometry = axle.rightGeometry;
                outboardId = "FR_TIE_ROD_OUTBOARD";
                inboardId = "FR_TIE_ROD_INBOARD";
                offset_m = [0, -0.002, 0];
                row = geometry.hardpoints.ids == inboardId;
                geometry.hardpoints.xyz_m(row,:) = ...
                    fsd.model.getPoint(geometry, outboardId) + offset_m;
                axle = fsd.model.createAxleGeometry( ...
                    axle.leftGeometry, geometry);
            else
                geometry = axle.leftGeometry;
                outboardId = "FL_TIE_ROD_OUTBOARD";
                inboardId = "FL_TIE_ROD_INBOARD";
                offset_m = [0, 0.002, 0];
                row = geometry.hardpoints.ids == inboardId;
                geometry.hardpoints.xyz_m(row,:) = ...
                    fsd.model.getPoint(geometry, outboardId) + offset_m;
                axle = fsd.model.createAxleGeometry( ...
                    geometry, axle.rightGeometry);
            end
            steering = fsd.model.createSteeringSystem(axle, 1.6, "m");
        end

        function heading = tangent(contact_m, icr_xy_m)
            radius = icr_xy_m - contact_m(1:2);
            heading = [-radius(2), radius(1), 0];
            if heading(1) > 0
                heading = -heading;
            end
            heading = heading / norm(heading);
        end
    end
end

function closeIfValid(figureHandle)
if isgraphics(figureHandle, "figure")
    close(figureHandle);
end
end
