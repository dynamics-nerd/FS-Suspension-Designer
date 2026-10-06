classdef TestFrontViewRollCenter < matlab.unittest.TestCase
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
        function velocityConstraintReducesToClassicFrontView(testCase)
            axle = analyticAxleFixture(false);
            ic = fsd.analysis.frontViewInstantCenter(axle.leftGeometry);
            testCase.verifyEqual(ic.status, "FINITE");
            testCase.verifyEqual(ic.point_yz_m, [-1/10, 1/4], ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(testCase.lineValue( ...
                ic.upperLine, [-0.6, 5/12]), 0, "AbsTol", 1e-14);
            testCase.verifyEqual(testCase.lineValue( ...
                ic.lowerLine, [-0.6, 1/12]), 0, "AbsTol", 1e-14);
        end

        function symmetricBenchmarkHasKnownRollCenter(testCase)
            analysis = fsd.analysis.rollCenter(analyticAxleFixture(false));
            testCase.verifyEqual(analysis.status, "FINITE");
            testCase.verifyEqual(analysis.left.instantCenter.point_yz_m, ...
                [-1/10, 1/4], "AbsTol", 1e-14);
            testCase.verifyEqual(analysis.right.instantCenter.point_yz_m, ...
                [1/10, 1/4], "AbsTol", 1e-14);
            testCase.verifyEqual(analysis.rollCenterY_m, 0, ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(analysis.rollCenterZ_m, 13/44, ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(analysis.rollCenterHeight_m, 13/44, ...
                "AbsTol", 1e-14);
        end

        function asymmetricBenchmarkDoesNotForceCenterline(testCase)
            analysis = fsd.analysis.rollCenter(analyticAxleFixture(true));
            testCase.verifyEqual(analysis.right.instantCenter.point_yz_m, ...
                [-1/5, 3/10], "AbsTol", 1e-14);
            testCase.verifyEqual(analysis.rollCenterY_m, -247/3020, ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(analysis.rollCenterZ_m, 429/1661, ...
                "AbsTol", 1e-14);
            testCase.verifyGreaterThan(abs(analysis.rollCenterY_m), 1e-6);
        end

        function wheelStaggerDoesNotAffectKinematicConstruction(testCase)
            axle = analyticAxleFixture(false);
            baseline = fsd.analysis.rollCenter(axle);
            right = axle.rightGeometry;
            ids = right.hardpoints.ids;
            right.hardpoints.xyz_m( ...
                ids == "FR_WHEEL_CENTER", 1) = 0.020;
            right.hardpoints.xyz_m( ...
                ids == "FR_CONTACT_PATCH", 1) = 0.020;
            fsd.model.validateDoubleWishboneGeometry(right);
            staggered = fsd.model.createAxleGeometry( ...
                axle.leftGeometry, right);
            analysis = fsd.analysis.rollCenter(staggered);
            testCase.verifyFalse(isfield(analysis, "xReference_m"));
            testCase.verifyEqual(analysis.left.instantCenter.point_yz_m, ...
                baseline.left.instantCenter.point_yz_m, "AbsTol", 1e-14);
            testCase.verifyEqual(analysis.right.instantCenter.point_yz_m, ...
                baseline.right.instantCenter.point_yz_m, "AbsTol", 1e-14);
            testCase.verifyEqual(analysis.rollCenterY_m, ...
                baseline.rollCenterY_m, "AbsTol", 1e-14);
            testCase.verifyEqual(analysis.rollCenterZ_m, ...
                baseline.rollCenterZ_m, "AbsTol", 1e-14);
        end

        function threeDimensionalAxisUsesInstantaneousVelocity(testCase)
            geometry = threeDimensionalCornerFixture();
            ids = geometry.hardpoints.ids;
            pivotFwd = geometry.hardpoints.xyz_m( ...
                ids == "FL_UCA_FWD_CHASSIS", :);
            pivotAft = geometry.hardpoints.xyz_m( ...
                ids == "FL_UCA_AFT_CHASSIS", :);
            ballJoint = geometry.hardpoints.xyz_m(ids == "FL_UBJ", :);
            constraint = fsd.geometry.frontViewKinematicConstraint( ...
                pivotFwd, pivotAft, ballJoint);

            u = (pivotAft - pivotFwd) / norm(pivotAft - pivotFwd);
            axisPoint = pivotFwd + dot(ballJoint - pivotFwd, u) * u;
            velocity = cross(u, ballJoint - axisPoint);
            expected = velocity(2:3) / norm(velocity(2:3));
            testCase.verifyEqual(constraint.status, "FINITE");
            testCase.verifyEqual(abs(dot( ...
                constraint.projectedVelocityDirection_yz, expected)), ...
                1, "AbsTol", 2e-14);
            testCase.verifyEqual(testCase.lineValue( ...
                constraint.line, ballJoint(2:3)), 0, "AbsTol", 2e-14);
            testCase.verifyEqual(dot(constraint.line.direction_yz, ...
                expected), 0, "AbsTol", 2e-14);
        end

        function pivotOrderDoesNotChangeConstraint(testCase)
            geometry = threeDimensionalCornerFixture();
            ids = geometry.hardpoints.ids;
            fwd = geometry.hardpoints.xyz_m( ...
                ids == "FL_LCA_FWD_CHASSIS", :);
            aft = geometry.hardpoints.xyz_m( ...
                ids == "FL_LCA_AFT_CHASSIS", :);
            joint = geometry.hardpoints.xyz_m(ids == "FL_LBJ", :);
            first = fsd.geometry.frontViewKinematicConstraint(fwd, aft, joint);
            reversed = fsd.geometry.frontViewKinematicConstraint( ...
                aft, fwd, joint);
            testCase.verifyEqual(first.line.homogeneousLine, ...
                reversed.line.homogeneousLine, "AbsTol", 2e-14);
        end

        function stronglyObliqueAxisMatchesIndependentVelocity(testCase)
            pivotFwd = [-0.30, 0.10, -0.20];
            pivotAft = [0.40, 0.55, 0.65];
            ballJoint = [0.15, -0.70, 0.35];
            constraint = fsd.geometry.frontViewKinematicConstraint( ...
                pivotFwd, pivotAft, ballJoint);
            u = (pivotAft - pivotFwd) / norm(pivotAft - pivotFwd);
            radial = ballJoint - pivotFwd - ...
                dot(ballJoint - pivotFwd, u) * u;
            projectedVelocity = cross(u, radial);
            projectedVelocity = projectedVelocity(2:3);
            testCase.verifyEqual(constraint.status, "FINITE");
            testCase.verifyEqual(abs(dot( ...
                constraint.projectedVelocityDirection_yz, ...
                projectedVelocity / norm(projectedVelocity))), ...
                1, "AbsTol", 2e-14);
            testCase.verifyEqual(testCase.lineValue( ...
                constraint.line, ballJoint(2:3)), 0, "AbsTol", 2e-14);
        end

        function longitudinalBallJointStaggerHasNoCommonXPlane(testCase)
            geometry = threeDimensionalCornerFixture();
            ids = geometry.hardpoints.ids;
            ubj = geometry.hardpoints.xyz_m(ids == "FL_UBJ", :);
            lbj = geometry.hardpoints.xyz_m(ids == "FL_LBJ", :);
            testCase.verifyNotEqual(ubj(1), lbj(1));
            ic = fsd.analysis.frontViewInstantCenter(geometry);
            expected = testCase.independentFvic(geometry, ubj, lbj);
            testCase.verifyEqual(ic.status, "FINITE");
            testCase.verifyEqual(ic.point_yz_m, expected, ...
                "AbsTol", 2e-14);
        end

        function sectionPlaneShortcutFailsForSkewAxis(testCase)
            geometry = threeDimensionalCornerFixture();
            ids = geometry.hardpoints.ids;
            fwd = geometry.hardpoints.xyz_m( ...
                ids == "FL_UCA_FWD_CHASSIS", :);
            aft = geometry.hardpoints.xyz_m( ...
                ids == "FL_UCA_AFT_CHASSIS", :);
            joint = geometry.hardpoints.xyz_m(ids == "FL_UBJ", :);
            constraint = fsd.geometry.frontViewKinematicConstraint( ...
                fwd, aft, joint);
            oldPlaneNormal = cross(aft - fwd, joint - fwd);
            oldD = -dot(oldPlaneNormal, fwd);
            oldSectionResidualAtJointYZ = oldPlaneNormal(2) * joint(2) + ...
                oldPlaneNormal(3) * joint(3) + oldD;
            testCase.verifyGreaterThan(abs(oldSectionResidualAtJointYZ), 1e-6);
            testCase.verifyEqual(testCase.lineValue( ...
                constraint.line, joint(2:3)), 0, "AbsTol", 2e-14);
        end

        function finiteDifferenceMotionConfirmsConstraintAndFvic(testCase)
            geometry = threeDimensionalCornerFixture();
            step_m = 1e-5;
            centerTravel_m = 0.020;
            sweep = fsd.kinematics.solveBumpSweep( ...
                geometry, centerTravel_m + [-step_m; 0; step_m], "m");
            testCase.assertTrue(sweep.allConverged, ...
                strjoin(string({sweep.results.failureReason}), newline));
            minus = sweep.results(1);
            center = sweep.results(2);
            plus = sweep.results(3);
            velocityUpper = (plus.state.ubj_m - minus.state.ubj_m) / ...
                (2 * step_m);
            velocityLower = (plus.state.lbj_m - minus.state.lbj_m) / ...
                (2 * step_m);
            ic = fsd.analysis.frontViewInstantCenter(geometry, center);
            testCase.verifyEqual(ic.status, "FINITE");
            testCase.verifyEqual(abs(dot( ...
                velocityUpper(2:3) / norm(velocityUpper(2:3)), ...
                ic.upperConstraint.projectedVelocityDirection_yz)), ...
                1, "AbsTol", 2e-7);
            testCase.verifyEqual(abs(dot( ...
                velocityLower(2:3) / norm(velocityLower(2:3)), ...
                ic.lowerConstraint.projectedVelocityDirection_yz)), ...
                1, "AbsTol", 2e-7);
            velocityMatrix = [velocityUpper(2:3); velocityLower(2:3)];
            rightHandSide = [dot(velocityUpper(2:3), center.state.ubj_m(2:3)); ...
                dot(velocityLower(2:3), center.state.lbj_m(2:3))];
            expectedIc = (velocityMatrix \ rightHandSide).';
            testCase.verifyEqual(ic.point_yz_m, expectedIc, ...
                "AbsTol", 2e-7);
        end

        function idealWheelContactUsesLowestCirclePoint(testCase)
            axle = analyticAxleFixture(false);
            contact = fsd.analysis.geometricWheelContact( ...
                axle.leftGeometry);
            testCase.verifyEqual(contact.geometricRadius_m, 0.25, ...
                "AbsTol", 1e-15);
            testCase.verifyEqual(contact.point_m, [0, -0.65, 0], ...
                "AbsTol", 1e-15);
        end

        function dynamicContactIsNotRigidDatum(testCase)
            axle = analyticAxleFixture(false);
            result = fsd.kinematics.solveBump( ...
                axle.leftGeometry, 10, "mm");
            contact = fsd.analysis.geometricWheelContact( ...
                axle.leftGeometry, result);
            testCase.verifyTrue(result.converged, result.failureReason);
            testCase.verifyEqual(norm(contact.point_m - ...
                result.state.wheelCenter_m), 0.25, "AbsTol", 1e-12);
            testCase.verifyEqual(dot(contact.point_m - ...
                result.state.wheelCenter_m, result.wheelAxis), 0, ...
                "AbsTol", 1e-12);
        end

        function rejectsIncompatibleStaticContactDatum(testCase)
            axle = analyticAxleFixture(false);
            geometry = axle.leftGeometry;
            row = geometry.hardpoints.ids == "FL_CONTACT_PATCH";
            geometry.hardpoints.xyz_m(row, 2) = ...
                geometry.hardpoints.xyz_m(row, 2) + 0.010;
            fsd.model.validateDoubleWishboneGeometry(geometry);
            testCase.verifyError(@() ...
                fsd.analysis.geometricWheelContact(geometry), ...
                "fsd:analysis:IncompatibleWheelContactDatum");
        end

        function verticalWheelAxisReturnsDegenerateContact(testCase)
            contact = fsd.geometry.geometricWheelContact( ...
                [0, 0, 0.25], [0, 0, 1], 0.25);
            testCase.verifyEqual(contact.status, "DEGENERATE");
            testCase.verifyTrue(all(isnan(contact.point_m)));
        end

        function classifiesProjectiveLineIntersections(testCase)
            lineA = fsd.geometry.lineYZFromPoints([0, 0], [1, 1]);
            lineParallel = fsd.geometry.lineYZFromPoints([0, 1], [1, 2]);
            lineCoincident = fsd.geometry.lineYZFromPoints([2, 2], [3, 3]);
            lineDegenerate = fsd.geometry.lineYZFromPoints([1, 1], [1, 1]);
            parallel = fsd.geometry.intersectLinesYZ(lineA, lineParallel);
            testCase.verifyEqual(parallel.status, "INFINITE");
            testCase.verifyEqual(parallel.homogeneousPoint(3), 0);
            testCase.verifyEqual(norm(parallel.direction_yz), 1, ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(fsd.geometry.intersectLinesYZ( ...
                lineA, lineCoincident).status, "COINCIDENT");
            testCase.verifyEqual(lineDegenerate.status, "DEGENERATE");
        end

        function nearParallelIntersectionReportsConditioning(testCase)
            lineA = fsd.geometry.lineYZFromPoints([0, 0], [1, 0]);
            lineB = fsd.geometry.lineYZFromPoints([0, 1], [1, 1 + 1e-10]);
            intersection = fsd.geometry.intersectLinesYZ(lineA, lineB);
            testCase.verifyEqual(intersection.status, "FINITE");
            testCase.verifyTrue(intersection.isIllConditioned);
            testCase.verifyLessThan(intersection.conditioning, sqrt(eps));
            testCase.verifyGreaterThan(intersection.conditioning, 0);
        end

        function finitePointAndInfiniteDirectionDefineLine(testCase)
            line = fsd.geometry.lineYZFromHomogeneousPoints( ...
                [-0.65, 0, 1], [3, -1, 0]);
            testCase.verifyEqual(line.status, "FINITE");
            testCase.verifyEqual(testCase.lineValue(line, [-0.65, 0]), ...
                0, "AbsTol", 1e-14);
            testCase.verifyEqual(abs(dot(line.direction_yz, ...
                [3, -1] / sqrt(10))), 1, "AbsTol", 1e-14);
        end

        function parallelWishbonesReportInfiniteIcWithoutFakePoint(testCase)
            axle = analyticAxleFixture(false);
            geometry = testCase.makeLeftWishbonesParallel( ...
                axle.leftGeometry);
            ic = fsd.analysis.frontViewInstantCenter(geometry);
            testCase.verifyEqual(ic.status, "INFINITE");
            testCase.verifyTrue(all(isnan(ic.point_yz_m)));
            testCase.verifyEqual(ic.homogeneousPoint(3), 0);
            testCase.verifyEqual(norm(ic.direction_yz), 1, ...
                "AbsTol", 1e-14);
        end

        function infiniteInstantCentersCanProduceFiniteRollCenter(testCase)
            axle = analyticAxleFixture(false);
            left = testCase.makeLeftWishbonesParallel(axle.leftGeometry);
            right = fsd.geometry.reflectDoubleWishboneGeometry(left);
            parallelAxle = fsd.model.createAxleGeometry(left, right);
            analysis = fsd.analysis.rollCenter(parallelAxle);
            testCase.verifyEqual(analysis.left.instantCenter.status, ...
                "INFINITE");
            testCase.verifyEqual(analysis.right.instantCenter.status, ...
                "INFINITE");
            testCase.verifyEqual(analysis.status, "FINITE");
            testCase.verifyEqual(analysis.rollCenterY_m, 0, ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(analysis.rollCenterZ_m, -13/60, ...
                "AbsTol", 1e-14);
        end

        function coincidentWishboneLinesHaveExplicitStatus(testCase)
            axle = analyticAxleFixture(false);
            geometry = axle.leftGeometry;
            ids = geometry.hardpoints.ids;
            geometry.hardpoints.xyz_m( ...
                ids == "FL_LCA_FWD_CHASSIS", 2:3) = [-0.35, 1/3];
            geometry.hardpoints.xyz_m( ...
                ids == "FL_LCA_AFT_CHASSIS", 2:3) = [-0.35, 1/3];
            geometry.hardpoints.xyz_m( ...
                ids == "FL_LBJ", 2:3) = [-0.55, 0.4];
            fsd.model.validateDoubleWishboneGeometry(geometry);
            ic = fsd.analysis.frontViewInstantCenter(geometry);
            testCase.verifyEqual(ic.status, "COINCIDENT");
            testCase.verifyTrue(all(isnan(ic.point_yz_m)));
        end

        function degenerateWishboneAxisIsDetected(testCase)
            axle = analyticAxleFixture(false);
            geometry = axle.leftGeometry;
            ids = geometry.hardpoints.ids;
            geometry.hardpoints.xyz_m(ids == "FL_UBJ", :) = ...
                [0, -0.4, 0.35];
            fsd.model.validateDoubleWishboneGeometry(geometry);
            ic = fsd.analysis.frontViewInstantCenter(geometry);
            testCase.verifyEqual(ic.status, "DEGENERATE");
            testCase.verifyEqual(ic.upperConstraint.degeneracy, ...
                "BALL_JOINT_ON_AXIS");
        end

        function projectedVelocityDegeneracyIsExplicit(testCase)
            constraint = fsd.geometry.frontViewKinematicConstraint( ...
                [0, 0, 0], [0, 1, 0], [0, 0, 1]);
            testCase.verifyEqual(constraint.status, "DEGENERATE");
            testCase.verifyEqual(constraint.degeneracy, ...
                "PROJECTED_VELOCITY");
        end

        function coincidentPivotsAreExplicitlyDegenerate(testCase)
            constraint = fsd.geometry.frontViewKinematicConstraint( ...
                [0.1, -0.4, 0.3], [0.1, -0.4, 0.3], ...
                [0, -0.6, 0.4]);
            testCase.verifyEqual(constraint.status, "DEGENERATE");
            testCase.verifyEqual(constraint.degeneracy, "PIVOT_AXIS");
            testCase.verifyTrue(all(isnan( ...
                constraint.line.homogeneousLine)));
        end

        function parallelConstructionLinesProduceInfiniteRc(testCase)
            axle = analyticAxleFixture(false);
            right = testCase.setRightIc(axle.rightGeometry, 0.1, -0.25);
            axle = fsd.model.createAxleGeometry(axle.leftGeometry, right);
            analysis = fsd.analysis.rollCenter(axle);
            testCase.verifyEqual(analysis.status, "INFINITE");
            testCase.verifyTrue(isnan(analysis.rollCenterY_m));
            testCase.verifyTrue(isnan(analysis.rollCenterZ_m));
            testCase.verifyEqual(norm(analysis.rollCenterDirection_yz), ...
                1, "AbsTol", 1e-14);
            testCase.verifyEqual(analysis.rollCenterHeightStatus, ...
                "ROLL_CENTER_INFINITE");
        end

        function plotsFiniteFrontView(testCase)
            analysis = fsd.analysis.rollCenter(analyticAxleFixture(false));
            figureHandle = figure("Visible", "off");
            testCase.addTeardown(@() closeIfValid(figureHandle));
            handles = fsd.analysis.plotAxleFrontView( ...
                analysis, axes(figureHandle));
            testCase.verifyTrue(isgraphics(handles.axes, "axes"));
            testCase.verifyTrue(isgraphics(handles.rollCenter));
            testCase.verifyEqual(handles.axes.DataAspectRatio, [1, 1, 1]);
        end
    end

    methods (Static, Access = private)
        function value = lineValue(line, point_yz_m)
            value = line.homogeneousLine * [point_yz_m, 1].';
        end

        function geometry = makeLeftWishbonesParallel(geometry)
            row = geometry.hardpoints.ids == "FL_LBJ";
            geometry.hardpoints.xyz_m(row, 3) = 13/60;
            fsd.model.validateDoubleWishboneGeometry(geometry);
        end

        function geometry = setRightIc(geometry, icY_m, icZ_m)
            ids = geometry.hardpoints.ids;
            upperInboard = geometry.hardpoints.xyz_m( ...
                ids == "FR_UCA_FWD_CHASSIS", 2:3);
            lowerInboard = geometry.hardpoints.xyz_m( ...
                ids == "FR_LCA_FWD_CHASSIS", 2:3);
            ubjY_m = geometry.hardpoints.xyz_m(ids == "FR_UBJ", 2);
            lbjY_m = geometry.hardpoints.xyz_m(ids == "FR_LBJ", 2);
            upperSlope = (icZ_m - upperInboard(2)) / ...
                (icY_m - upperInboard(1));
            lowerSlope = (icZ_m - lowerInboard(2)) / ...
                (icY_m - lowerInboard(1));
            geometry.hardpoints.xyz_m(ids == "FR_UBJ", 3) = ...
                upperInboard(2) + upperSlope * ...
                (ubjY_m - upperInboard(1));
            geometry.hardpoints.xyz_m(ids == "FR_LBJ", 3) = ...
                lowerInboard(2) + lowerSlope * ...
                (lbjY_m - lowerInboard(1));
            fsd.model.validateDoubleWishboneGeometry(geometry);
        end


        function point_yz_m = independentFvic(geometry, ubj, lbj)
            ids = geometry.hardpoints.ids;
            upperFwd = geometry.hardpoints.xyz_m( ...
                ids == "FL_UCA_FWD_CHASSIS", :);
            upperAft = geometry.hardpoints.xyz_m( ...
                ids == "FL_UCA_AFT_CHASSIS", :);
            lowerFwd = geometry.hardpoints.xyz_m( ...
                ids == "FL_LCA_FWD_CHASSIS", :);
            lowerAft = geometry.hardpoints.xyz_m( ...
                ids == "FL_LCA_AFT_CHASSIS", :);
            upperVelocity = TestFrontViewRollCenter.axisVelocity( ...
                upperFwd, upperAft, ubj);
            lowerVelocity = TestFrontViewRollCenter.axisVelocity( ...
                lowerFwd, lowerAft, lbj);
            matrix = [upperVelocity(2:3); lowerVelocity(2:3)];
            rhs = [dot(upperVelocity(2:3), ubj(2:3)); ...
                dot(lowerVelocity(2:3), lbj(2:3))];
            point_yz_m = (matrix \ rhs).';
        end

        function velocity = axisVelocity(pivotFwd, pivotAft, ballJoint)
            u = (pivotAft - pivotFwd) / norm(pivotAft - pivotFwd);
            radial = ballJoint - pivotFwd - ...
                dot(ballJoint - pivotFwd, u) * u;
            velocity = cross(u, radial);
        end
    end
end

function closeIfValid(figureHandle)
if isgraphics(figureHandle, "figure")
    close(figureHandle);
end
end
