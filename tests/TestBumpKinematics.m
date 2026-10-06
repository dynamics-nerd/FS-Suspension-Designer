classdef TestBumpKinematics < matlab.unittest.TestCase
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
        function staticStateIsExact(testCase)
            geometry = testCase.benchmarkGeometry();
            result = fsd.kinematics.solveBump(geometry, 0, "mm");

            testCase.verifyTrue(result.converged);
            testCase.verifyEqual(result.achievedWheelTravel_m, 0);
            testCase.verifyEqual(result.uprightPose.rotationMatrix, eye(3));
            testCase.verifyEqual(result.uprightPose.translation_m, [0, 0, 0]);
            testCase.verifyEqual(result.state.xyz_m, ...
                testCase.staticUprightPoints(geometry));
            testCase.verifyEqual(result.wheelAxis, geometry.wheel.wheelAxis);
        end

        function achievesPositiveBump(testCase)
            geometry = testCase.benchmarkGeometry();
            result = fsd.kinematics.solveBump(geometry, 20, "mm");
            staticWheelCenter = fsd.model.getPoint(geometry, ...
                "FL_WHEEL_CENTER");

            testCase.verifyTrue(result.converged, result.failureReason);
            testCase.verifyEqual(result.state.wheelCenter_m(3), ...
                staticWheelCenter(3) + 0.020, "AbsTol", 2e-9);
            testCase.verifyGreaterThan(result.achievedWheelTravel_m, 0);
        end

        function achievesNegativeRebound(testCase)
            geometry = testCase.benchmarkGeometry();
            result = fsd.kinematics.solveBump(geometry, -20, "mm");
            staticWheelCenter = fsd.model.getPoint(geometry, ...
                "FL_WHEEL_CENTER");

            testCase.verifyTrue(result.converged, result.failureReason);
            testCase.verifyEqual(result.state.wheelCenter_m(3), ...
                staticWheelCenter(3) - 0.020, "AbsTol", 2e-9);
            testCase.verifyLessThan(result.achievedWheelTravel_m, 0);
        end

        function preservesControlArmLengths(testCase)
            geometry = testCase.benchmarkGeometry();
            result = fsd.kinematics.solveBump(geometry, 25, "mm");
            testCase.verifyTrue(result.converged, result.failureReason);
            prefix = "FL_";
            testCase.verifyLinkLength(geometry, result.state.ubj_m, ...
                prefix + "UCA_FWD_CHASSIS");
            testCase.verifyLinkLength(geometry, result.state.ubj_m, ...
                prefix + "UCA_AFT_CHASSIS");
            testCase.verifyLinkLength(geometry, result.state.lbj_m, ...
                prefix + "LCA_FWD_CHASSIS");
            testCase.verifyLinkLength(geometry, result.state.lbj_m, ...
                prefix + "LCA_AFT_CHASSIS");
        end

        function preservesTieRodLength(testCase)
            geometry = testCase.benchmarkGeometry();
            result = fsd.kinematics.solveBump(geometry, 25, "mm");
            tieIn = fsd.model.getPoint(geometry, "FL_TIE_ROD_INBOARD");
            tieOutStatic = fsd.model.getPoint(geometry, "FL_TIE_ROD_OUTBOARD");
            testCase.verifyEqual(norm(result.state.tieRodOutboard_m - tieIn), ...
                norm(tieOutStatic - tieIn), "AbsTol", 2e-9);
        end

        function uprightRemainsRigid(testCase)
            geometry = testCase.benchmarkGeometry();
            result = fsd.kinematics.solveBump(geometry, 25, "mm");
            staticPoints = testCase.staticUprightPoints(geometry);
            pairs = [1 2; 1 3; 2 3];
            for index = 1:size(pairs, 1)
                pair = pairs(index, :);
                testCase.verifyEqual(norm( ...
                    result.state.xyz_m(pair(2),:) - ...
                    result.state.xyz_m(pair(1),:)), ...
                    norm(staticPoints(pair(2),:) - staticPoints(pair(1),:)), ...
                    "AbsTol", 2e-9);
            end
        end

        function wheelAttachmentRemainsRigid(testCase)
            geometry = testCase.benchmarkGeometry();
            result = fsd.kinematics.solveBump(geometry, 25, "mm");
            staticPoints = testCase.staticUprightPoints(geometry);

            testCase.verifyEqual(norm(result.state.wheelCenter_m - ...
                result.state.ubj_m), norm(staticPoints(4,:) - staticPoints(1,:)), ...
                "AbsTol", 2e-9);
            testCase.verifyEqual(norm(result.state.contactPatch_m - ...
                result.state.wheelCenter_m), ...
                norm(staticPoints(5,:) - staticPoints(4,:)), "AbsTol", 2e-9);
            expectedAxis = (result.uprightPose.rotationMatrix * ...
                geometry.wheel.wheelAxis')';
            testCase.verifyEqual(result.wheelAxis, expectedAxis, ...
                "AbsTol", 1e-12);
        end

        function wheelAxisRemainsUnit(testCase)
            result = fsd.kinematics.solveBump( ...
                testCase.benchmarkGeometry(), 25, "mm");
            testCase.verifyEqual(norm(result.wheelAxis), 1, "AbsTol", 1e-12);
        end

        function benchmarkMatchesAnalyticTranslation(testCase)
            geometry = testCase.benchmarkGeometry();
            travel_m = 0.030;
            result = fsd.kinematics.solveBump(geometry, travel_m, "m");
            expectedDeltaY_m = 0.3 - sqrt(0.3^2 - travel_m^2);

            testCase.verifyTrue(result.converged, result.failureReason);
            testCase.verifyEqual(result.uprightPose.translation_m, ...
                [0, expectedDeltaY_m, travel_m], "AbsTol", 2e-8);
            testCase.verifyEqual(result.uprightPose.rotationMatrix, eye(3), ...
                "AbsTol", 2e-8);
            testCase.verifyEqual(result.camber_rad, 0, "AbsTol", 2e-8);
        end

        function reflectedCornerProducesReflectedState(testCase)
            leftGeometry = testCase.benchmarkGeometry();
            rightGeometry = fsd.geometry.reflectDoubleWishboneGeometry( ...
                leftGeometry);
            left = fsd.kinematics.solveBump(leftGeometry, 20, "mm");
            right = fsd.kinematics.solveBump(rightGeometry, 20, "mm");

            testCase.verifyTrue(left.converged && right.converged);
            testCase.verifyEqual(right.state.xyz_m(:,[1,3]), ...
                left.state.xyz_m(:,[1,3]), "AbsTol", 2e-8);
            testCase.verifyEqual(right.state.xyz_m(:,2), ...
                -left.state.xyz_m(:,2), "AbsTol", 2e-8);
            testCase.verifyEqual(right.camber_rad, left.camber_rad, ...
                "AbsTol", 2e-8);
        end

        function camberSignIsSideIndependent(testCase)
            angle = 5 * pi / 180;
            flNegative = fsd.kinematics.camberFromWheelAxis( ...
                [0, -cos(angle), sin(angle)], "FL");
            frNegative = fsd.kinematics.camberFromWheelAxis( ...
                [0, cos(angle), sin(angle)], "FR");
            flPositive = fsd.kinematics.camberFromWheelAxis( ...
                [0, -cos(angle), -sin(angle)], "FL");

            testCase.verifyEqual(flNegative, -angle, "AbsTol", 1e-14);
            testCase.verifyEqual(frNegative, -angle, "AbsTol", 1e-14);
            testCase.verifyEqual(flPositive, angle, "AbsTol", 1e-14);
        end

        function sweepIsContinuous(testCase)
            geometry = testCase.benchmarkGeometry();
            sweep = fsd.kinematics.solveBumpSweep( ...
                geometry, (-30:5:30)', "mm");

            testCase.verifyTrue(sweep.allConverged);
            wheelCenters = vertcat(sweep.results.state);
            wheelCenters = vertcat(wheelCenters.wheelCenter_m);
            jumps_m = sqrt(sum(diff(wheelCenters, 1, 1).^2, 2));
            testCase.verifyLessThan(max(jumps_m), 0.010);
            testCase.verifyEqual(sweep.camber_rad, zeros(13,1), ...
                "AbsTol", 2e-8);
        end

        function continuationRoundTripReturnsStatic(testCase)
            geometry = testCase.benchmarkGeometry();
            sweep = fsd.kinematics.solveBumpSweep( ...
                geometry, [0; 25; 0], "mm");
            finalState = sweep.results(3).state;

            testCase.verifyTrue(sweep.allConverged);
            testCase.verifyEqual(finalState.xyz_m, ...
                testCase.staticUprightPoints(geometry), "AbsTol", 2e-8);
            testCase.verifyEqual(sweep.results(3).uprightPose.rotationMatrix, ...
                eye(3), "AbsTol", 2e-8);
        end

        function impossibleTravelReturnsExplicitFailure(testCase)
            result = fsd.kinematics.solveBump( ...
                testCase.benchmarkGeometry(), 500, "mm");
            testCase.verifyFalse(result.converged);
            testCase.verifyEqual(result.status, "NO_CONVERGENCE");
            testCase.verifyTrue(all(isnan(result.state.xyz_m), "all"));
            testCase.verifyTrue(isnan(result.camber_rad));
        end

        function plotComparesStaticAndCurrent(testCase)
            geometry = testCase.benchmarkGeometry();
            result = fsd.kinematics.solveBump(geometry, 20, "mm");
            figureHandle = figure("Visible", "off");
            testCase.addTeardown(@() closeIfValid(figureHandle));
            axesHandle = axes(figureHandle);
            handles = fsd.kinematics.plotBumpResult( ...
                geometry, result, axesHandle);
            testCase.verifyTrue(all(isgraphics(handles.currentMembers)));
            testCase.verifyTrue(isgraphics(handles.currentWheelAxis));
        end
    end

    methods (Access = private)
        function verifyLinkLength(testCase, geometry, currentOutboard_m, inboardId)
            inboard_m = fsd.model.getPoint(geometry, inboardId);
            if contains(inboardId, "UCA")
                staticOutboard_m = fsd.model.getPoint(geometry, "FL_UBJ");
            else
                staticOutboard_m = fsd.model.getPoint(geometry, "FL_LBJ");
            end
            testCase.verifyEqual(norm(currentOutboard_m - inboard_m), ...
                norm(staticOutboard_m - inboard_m), "AbsTol", 2e-9);
        end
    end

    methods (Static, Access = private)
        function geometry = benchmarkGeometry()
            corner = "FL";
            ids = corner + "_" + fsd.model.requiredHardpointRoles();
            xyz_m = [ ...
                -0.100, -0.300, 0.400; ...
                 0.100, -0.300, 0.400; ...
                 0.000, -0.600, 0.400; ...
                -0.100, -0.300, 0.100; ...
                 0.100, -0.300, 0.100; ...
                 0.000, -0.600, 0.100; ...
                 0.050, -0.300, 0.250; ...
                 0.050, -0.600, 0.250; ...
                 0.000, -0.650, 0.250; ...
                 0.000, -0.650, 0.000];
            provenance = struct( ...
                "sourceKind", repmat("ASSUMED", 10, 3), ...
                "sourceNote", repmat("Analytic benchmark", 10, 3));
            geometry = fsd.model.createDoubleWishboneGeometry( ...
                corner, ids, xyz_m, "m", [0, -1, 0], provenance);
        end

        function points_m = staticUprightPoints(geometry)
            ids = geometry.upright.pointIds;
            points_m = zeros(numel(ids), 3);
            for index = 1:numel(ids)
                points_m(index,:) = fsd.model.getPoint(geometry, ids(index));
            end
        end
    end
end

function closeIfValid(figureHandle)
if isgraphics(figureHandle, "figure")
    close(figureHandle);
end
end

