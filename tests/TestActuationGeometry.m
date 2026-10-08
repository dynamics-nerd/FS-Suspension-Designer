classdef TestActuationGeometry < matlab.unittest.TestCase
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
        function createsCanonicalPushrod(testCase)
            [geometry, actuation] = actuationFixture();
            testCase.verifyEqual(actuation.schemaVersion, "0.7.0");
            testCase.verifyEqual(actuation.cornerId, geometry.cornerId);
            testCase.verifyEqual(actuation.actuationType, "PUSHROD");
            testCase.verifyEqual(actuation.suspensionAttachment.id, ...
                "ACTUATION_ROD_SUSPENSION");
            testCase.verifyTrue(fsd.model.validateActuationGeometry(actuation));
            testCase.verifyTrue(fsd.model.validateActuationIdentity( ...
                actuation.identity));
        end

        function publicUnitsAreEquivalent(testCase)
            [geometry, actuationM, definition] = actuationFixture();
            definition.suspensionAttachment.point = ...
                1000*definition.suspensionAttachment.point;
            definition.rocker.axis.point = 1000*definition.rocker.axis.point;
            definition.rocker.actuationRodPoint = ...
                1000*definition.rocker.actuationRodPoint;
            definition.rocker.damperPoint = ...
                1000*definition.rocker.damperPoint;
            definition.damper.chassisPoint = ...
                1000*definition.damper.chassisPoint;
            actuationMm = fsd.model.createActuationGeometry( ...
                geometry, definition, "mm");
            testCase.verifyEqual(actuationMm.identity, actuationM.identity);
        end

        function presetsHaveCanonicalAxes(testCase)
            [~, yz] = actuationFixture("YZ_PLANE");
            [~, xz] = actuationFixture("XZ_PLANE");
            testCase.verifyEqual(yz.rocker.axis.direction_unit, [1,0,0]);
            testCase.verifyEqual(xz.rocker.axis.direction_unit, [0,1,0]);
        end

        function orientationPresetIsNotPhysicalIdentity(testCase)
            [geometry, yz, definition] = actuationFixture("YZ_PLANE");
            definition.rocker.orientationMode = "CUSTOM";
            definition.rocker.axis.direction = [1,0,0];
            custom = fsd.model.createActuationGeometry( ...
                geometry, definition, "m");
            testCase.verifyEqual(custom.identity, yz.identity);
            testCase.verifyNotEqual(custom.rocker.orientationMode, ...
                yz.rocker.orientationMode);
        end

        function customAxisIsUnitAndOriented(testCase)
            [~, positive, definition] = actuationFixture("CUSTOM");
            testCase.verifyEqual(norm(positive.rocker.axis.direction_unit), ...
                1, "AbsTol", 1e-14);
            definition.rocker.axis.direction = ...
                -definition.rocker.axis.direction;
            negative = fsd.model.createActuationGeometry( ...
                translationAxleFixture("FRONT").leftGeometry, ...
                definition, "m");
            testCase.verifyNotEqual(positive.identity, negative.identity);
            testCase.verifyEqual(negative.rocker.axis.direction_unit, ...
                -positive.rocker.axis.direction_unit, "AbsTol", 1e-14);
        end

        function axisPointOnSameLineCanonicalizesIdentically(testCase)
            [geometry, original, definition] = actuationFixture("CUSTOM");
            direction = definition.rocker.axis.direction;
            direction = direction ./ norm(direction);
            definition.rocker.axis.point = ...
                definition.rocker.axis.point + 0.317*direction;
            shifted = fsd.model.createActuationGeometry( ...
                geometry, definition, "m");
            testCase.verifyEqual(shifted.rocker.axis.point_m, ...
                original.rocker.axis.point_m, "AbsTol", 1e-14);
            testCase.verifyEqual(shifted.identity, original.identity);
        end

        function pushrodPullrodHaveDistinctArchitectureIdentity(testCase)
            [geometry, pushrod, definition] = actuationFixture();
            definition.actuationType = "PULLROD";
            pullrod = fsd.model.createActuationGeometry( ...
                geometry, definition, "m");
            testCase.verifyNotEqual(pushrod.identity, pullrod.identity);
            testCase.verifyEqual(pullrod.actuationType, "PULLROD");
        end

        function supportsAllAttachmentBodies(testCase)
            for body = ["UPRIGHT", "UCA", "LCA"]
                [~, actuation] = actuationFixture( ...
                    "YZ_PLANE", body);
                testCase.verifyEqual( ...
                    actuation.suspensionAttachment.body, body);
            end
        end

        function rejectsInvalidAttachmentBody(testCase)
            [geometry, ~, definition] = actuationFixture();
            definition.suspensionAttachment.body = "CHASSIS";
            testCase.verifyError(@() fsd.model.createActuationGeometry( ...
                geometry, definition, "m"), ...
                "fsd:model:InvalidActuationDefinition");
        end

        function rejectsRockerRodPointOnAxis(testCase)
            [geometry, ~, definition] = actuationFixture();
            definition.rocker.actuationRodPoint = [0,0,0];
            testCase.verifyError(@() fsd.model.createActuationGeometry( ...
                geometry, definition, "m"), ...
                "fsd:model:RockerLeverArmDegenerate");
        end

        function rejectsDamperPointOnAxis(testCase)
            [geometry, ~, definition] = actuationFixture();
            definition.rocker.damperPoint = [0,0,0];
            testCase.verifyError(@() fsd.model.createActuationGeometry( ...
                geometry, definition, "m"), ...
                "fsd:model:RockerDamperLeverArmDegenerate");
        end
    end
end
