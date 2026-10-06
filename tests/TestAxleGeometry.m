classdef TestAxleGeometry < matlab.unittest.TestCase
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
        function createsCanonicalFrontAxle(testCase)
            axle = analyticAxleFixture(false);
            testCase.verifyTrue(fsd.model.validateAxleGeometry(axle));
            testCase.verifyEqual(axle.schemaVersion, "0.4.0");
            testCase.verifyEqual(axle.axleId, "FRONT");
            testCase.verifyEqual(axle.leftGeometry.cornerId, "FL");
            testCase.verifyEqual(axle.rightGeometry.cornerId, "FR");
            testCase.verifyFalse(isfield(axle, "xReference_m"));
        end

        function identityContainsBothCanonicalCorners(testCase)
            axle = analyticAxleFixture(false);
            identity = fsd.model.axleIdentity(axle);
            testCase.verifyTrue(fsd.model.validateAxleIdentity(identity));
            testCase.verifyEqual(identity.axleId, "FRONT");
            testCase.verifyEqual(identity.leftGeometryIdentity, ...
                fsd.model.geometryIdentity(axle.leftGeometry));
            testCase.verifyEqual(identity.rightGeometryIdentity, ...
                fsd.model.geometryIdentity(axle.rightGeometry));
            testCase.verifyFalse(isfield(identity, "xReference_m"));
        end

        function rejectsSwappedLeftAndRight(testCase)
            axle = analyticAxleFixture(false);
            testCase.verifyError(@() fsd.model.createAxleGeometry( ...
                axle.rightGeometry, axle.leftGeometry), ...
                "fsd:model:InvalidAxleCorners");
        end

        function rejectsMixedAxlesAndDuplicateSides(testCase)
            axle = analyticAxleFixture(false);
            rearRight = testCase.relabelCorner( ...
                axle.rightGeometry, "RR", 1.6);
            testCase.verifyError(@() fsd.model.createAxleGeometry( ...
                axle.leftGeometry, rearRight), ...
                "fsd:model:InvalidAxleCorners");
            testCase.verifyError(@() fsd.model.createAxleGeometry( ...
                axle.leftGeometry, axle.leftGeometry), ...
                "fsd:model:InvalidAxleCorners");
        end

        function createsRearAxle(testCase)
            front = analyticAxleFixture(false);
            rearLeft = testCase.relabelCorner( ...
                front.leftGeometry, "RL", 1.6);
            rearRight = testCase.relabelCorner( ...
                front.rightGeometry, "RR", 1.6);
            rear = fsd.model.createAxleGeometry(rearLeft, rearRight);
            testCase.verifyEqual(rear.axleId, "REAR");
            testCase.verifyFalse(isfield(rear, "xReference_m"));
        end

        function allowsAsymmetricGeometry(testCase)
            axle = analyticAxleFixture(true);
            testCase.verifyTrue(fsd.model.validateAxleGeometry(axle));
            testCase.verifyNotEqual( ...
                axle.leftGeometry.hardpoints.xyz_m(:, 3), ...
                axle.rightGeometry.hardpoints.xyz_m(:, 3));
        end

        function wheelStaggerDoesNotAddReferencePlane(testCase)
            axle = analyticAxleFixture(false);
            right = axle.rightGeometry;
            ids = right.hardpoints.ids;
            right.hardpoints.xyz_m( ...
                ids == "FR_WHEEL_CENTER", 1) = 0.020;
            right.hardpoints.xyz_m( ...
                ids == "FR_CONTACT_PATCH", 1) = 0.020;
            fsd.model.validateDoubleWishboneGeometry(right);
            staggered = fsd.model.createAxleGeometry( ...
                axle.leftGeometry, right);
            testCase.verifyFalse(isfield(staggered, "xReference_m"));
            testCase.verifyTrue(fsd.model.validateAxleGeometry(staggered));
        end
    end

    methods (Static, Access = private)
        function geometry = relabelCorner(geometry, newCorner, xOffset_m)
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
            geometry.hardpoints.xyz_m(:, 1) = ...
                geometry.hardpoints.xyz_m(:, 1) + xOffset_m;
            fsd.model.validateDoubleWishboneGeometry(geometry);
        end
    end
end
