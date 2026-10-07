classdef TestBodyRollGeometry < matlab.unittest.TestCase
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
        function zeroRollHasHorizontalRoad(testCase)
            frame = fsd.geometry.bodyRollRoadFrame(0);
            testCase.verifyEqual(frame.direction_yz, [1,0], "AbsTol", 1e-15);
            testCase.verifyEqual(frame.normal_yz, [0,1], "AbsTol", 1e-15);
        end

        function roadBasisIsOrthonormal(testCase)
            phi = deg2rad(7);
            frame = fsd.geometry.bodyRollRoadFrame(phi);
            testCase.verifyEqual(dot(frame.direction_yz, frame.normal_yz), ...
                0, "AbsTol", 1e-15);
            testCase.verifyEqual(norm(frame.direction_yz), 1, "AbsTol", 1e-15);
            testCase.verifyGreaterThan(frame.normal_yz(2), 0);
        end

        function angleUnitsConvertToRadians(testCase)
            testCase.verifyEqual(fsd.model.convertAngleToRadians(180, "deg"), ...
                pi, "AbsTol", 1e-15);
            testCase.verifyEqual(fsd.model.convertAngleToRadians(pi/3, "rad"), ...
                pi/3, "AbsTol", 1e-15);
        end

        function contactRoadLineUsesDeterministicNormal(testCase)
            left = [0,-0.6,0.04];
            right = [0,0.7,-0.02];
            line = fsd.geometry.roadLineFromContacts(left, right);
            testCase.verifyEqual(line.status, "FINITE");
            testCase.verifyEqual(norm(line.coefficients(1:2)), 1, ...
                "AbsTol", 1e-15);
            testCase.verifyGreaterThan(line.coefficients(2), 0);
            testCase.verifyEqual(line.coefficients*[left(2:3),1].', ...
                0, "AbsTol", 1e-15);
        end

        function detectsCoincidentAndInvertedContacts(testCase)
            coincident = fsd.geometry.roadLineFromContacts( ...
                [0,0,0], [1,0,0]);
            inverted = fsd.geometry.roadLineFromContacts( ...
                [0,1,0], [0,-1,0]);
            testCase.verifyEqual(coincident.status, "COINCIDENT_CONTACTS");
            testCase.verifyEqual(inverted.status, "INVERTED_CONTACT_ORDER");
        end

        function signedDistanceMatchesManualInclinedCase(testCase)
            normal = [3/5,4/5];
            line = struct("kind", "RoadLineYZ", "status", "FINITE", ...
                "coefficients", [normal,-2]);
            point = [5,1];
            testCase.verifyEqual(fsd.geometry.signedDistanceToRoadLine( ...
                point, line), 3/5*5 + 4/5*1 - 2, "AbsTol", 1e-15);
        end

        function rigidVerticalWheelsHaveAnalyticRoadCamber(testCase)
            for phi = deg2rad([-6,0,6])
                left = fsd.analysis.roadRelativeCamber([0,-1,0], "FL", phi);
                right = fsd.analysis.roadRelativeCamber([0,1,0], "FR", phi);
                testCase.verifyEqual(left, phi, "AbsTol", 2e-15);
                testCase.verifyEqual(right, -phi, "AbsTol", 2e-15);
            end
        end

        function rejectsAmbiguousRoadAngles(testCase)
            testCase.verifyError(@() fsd.geometry.bodyRollRoadFrame(pi/2), ...
                "fsd:geometry:InvalidBodyRollAngle");
        end
    end
end
