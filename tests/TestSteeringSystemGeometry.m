classdef TestSteeringSystemGeometry < matlab.unittest.TestCase
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
        function createsRackFromInnerJoints(testCase)
            axle = analyticAxleFixture(false);
            steering = fsd.model.createSteeringSystem(axle, 1.6, "m");
            testCase.verifyTrue( ...
                fsd.model.validateSteeringSystemGeometry(steering));
            testCase.verifyEqual(steering.schemaVersion, "0.5.0");
            testCase.verifyEqual(steering.rackGeometry.axisDirection, ...
                [0, 1, 0], "AbsTol", 1e-15);
            testCase.verifyEqual(steering.rackGeometry.jointSeparation_m, ...
                0.8, "AbsTol", 1e-15);
            testCase.verifyEqual(steering.rearAxleX_m, 1.6);
        end

        function convertsRearAxleReferenceAtBoundary(testCase)
            steering = fsd.model.createSteeringSystem( ...
                analyticAxleFixture(false), 1600, "mm");
            testCase.verifyEqual(steering.rearAxleX_m, 1.6, ...
                "AbsTol", 1e-15);
        end

        function rackAxisMayBeOblique(testCase)
            axle = analyticAxleFixture(false);
            right = axle.rightGeometry;
            row = right.hardpoints.ids == "FR_TIE_ROD_INBOARD";
            right.hardpoints.xyz_m(row,:) = ...
                right.hardpoints.xyz_m(row,:) + [0.02, 0, 0.01];
            fsd.model.validateDoubleWishboneGeometry(right);
            axle = fsd.model.createAxleGeometry(axle.leftGeometry, right);
            steering = fsd.model.createSteeringSystem(axle, 1.6, "m");
            expected = [0.02, 0.8, 0.01];
            expected = expected / norm(expected);
            testCase.verifyEqual(steering.rackGeometry.axisDirection, ...
                expected, "AbsTol", 1e-14);
        end

        function rejectsRearAxle(testCase)
            front = analyticAxleFixture(false);
            left = testCase.relabel(front.leftGeometry, "RL", 1.6);
            right = testCase.relabel(front.rightGeometry, "RR", 1.6);
            rear = fsd.model.createAxleGeometry(left, right);
            testCase.verifyError(@() fsd.model.createSteeringSystem( ...
                rear, 1.6, "m"), ...
                "fsd:model:SteeringRequiresFrontAxle");
        end

        function rejectsCoincidentRackJoints(testCase)
            axle = analyticAxleFixture(false);
            right = axle.rightGeometry;
            row = right.hardpoints.ids == "FR_TIE_ROD_INBOARD";
            right.hardpoints.xyz_m(row,:) = fsd.model.getPoint( ...
                axle.leftGeometry, "FL_TIE_ROD_INBOARD");
            fsd.model.validateDoubleWishboneGeometry(right);
            axle = fsd.model.createAxleGeometry(axle.leftGeometry, right);
            testCase.verifyError(@() fsd.model.createSteeringSystem( ...
                axle, 1.6, "m"), "fsd:model:DegenerateRackAxis");
        end

        function identityIncludesRearReference(testCase)
            axle = analyticAxleFixture(false);
            first = fsd.model.createSteeringSystem(axle, 1.6, "m");
            second = fsd.model.createSteeringSystem(axle, 1.7, "m");
            testCase.verifyNotEqual(first.identity, second.identity);
            testCase.verifyTrue( ...
                fsd.model.validateSteeringSystemIdentity(first.identity));
        end
    end

    methods (Static, Access = private)
        function geometry = relabel(geometry, newCorner, xOffset_m)
            oldCorner = string(geometry.cornerId);
            geometry.cornerId = newCorner;
            geometry.hardpoints.ids = newCorner + "_" + ...
                extractAfter(geometry.hardpoints.ids, ...
                strlength(oldCorner + "_"));
            geometry.connectivity.pointIds = newCorner + "_" + ...
                extractAfter(geometry.connectivity.pointIds, ...
                strlength(oldCorner + "_"));
            geometry.upright.pointIds = newCorner + "_" + ...
                extractAfter(geometry.upright.pointIds, ...
                strlength(oldCorner + "_"));
            geometry.wheel.centerId = newCorner + "_WHEEL_CENTER";
            geometry.wheel.contactPatchId = newCorner + "_CONTACT_PATCH";
            geometry.hardpoints.xyz_m(:,1) = ...
                geometry.hardpoints.xyz_m(:,1) + xOffset_m;
            fsd.model.validateDoubleWishboneGeometry(geometry);
        end
    end
end
