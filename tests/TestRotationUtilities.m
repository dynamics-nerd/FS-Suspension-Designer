classdef TestRotationUtilities < matlab.unittest.TestCase
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
        function zeroRotationIsIdentity(testCase)
            actual = fsd.geometry.rotationVectorToMatrix([0, 0, 0]);
            testCase.verifyEqual(actual, eye(3), "AbsTol", 1e-15);
        end

        function quarterTurnAboutXIsKnown(testCase)
            rotation = fsd.geometry.rotationVectorToMatrix([pi/2, 0, 0]);
            actual = (rotation * [0; 1; 0])';
            testCase.verifyEqual(actual, [0, 0, 1], "AbsTol", 1e-14);
        end

        function rotationIsProperOrthonormal(testCase)
            rotation = fsd.geometry.rotationVectorToMatrix([0.2, -0.3, 0.1]);
            testCase.verifyEqual(rotation' * rotation, eye(3), ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(det(rotation), 1, "AbsTol", 1e-14);
        end

        function rigidTransformPreservesDistance(testCase)
            points = [1, 0, 0; 0, 1, 0];
            rotation = fsd.geometry.rotationVectorToMatrix([0, 0, pi/3]);
            transformed = fsd.geometry.transformPointsRigid( ...
                points, [0, 0, 0], [2, -1, 0.5], rotation);
            testCase.verifyEqual(norm(transformed(2,:) - transformed(1,:)), ...
                sqrt(2), "AbsTol", 1e-14);
        end

        function rejectsImproperRotation(testCase)
            testCase.verifyError(@() fsd.geometry.transformPointsRigid( ...
                [0, 0, 0], [0, 0, 0], [0, 0, 0], diag([1, 1, -1])), ...
                "fsd:geometry:InvalidRotationMatrix");
        end
    end
end

