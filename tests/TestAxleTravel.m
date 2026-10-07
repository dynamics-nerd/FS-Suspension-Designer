classdef TestAxleTravel < matlab.unittest.TestCase
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
        function solvesIndependentTravelPairs(testCase)
            axle = analyticAxleFixture(false);
            pairs_mm = [15,-10; -12,8; 20,5];
            for pair = pairs_mm.'
                result = fsd.kinematics.solveAxleTravel(axle, pair.', "mm");
                testCase.assertTrue(result.converged, result.failureReason);
                testCase.verifyTrue(fsd.kinematics.validateAxleTravelResult(result));
                testCase.verifyEqual([result.leftResult.achievedWheelTravel_m, ...
                    result.rightResult.achievedWheelTravel_m], pair.'/1000, ...
                    "AbsTol", 2e-9);
                testCase.verifyEqual(norm(result.leftResult.wheelAxis), 1, ...
                    "AbsTol", 2e-12);
                testCase.verifyTrue(all(isfinite( ...
                    fsd.analysis.geometricWheelContact( ...
                    axle.rightGeometry, result.rightResult).point_m)));
            end
        end

        function equalTravelMatchesHistoricalHeave(testCase)
            axle = analyticAxleFixture(false);
            for travel_mm = [-20, 0, 15]
                general = fsd.kinematics.solveAxleTravel( ...
                    axle, [travel_mm, travel_mm], "mm");
                historical = fsd.kinematics.solveAxleHeave( ...
                    axle, travel_mm, "mm");
                testCase.verifyEqual(general.leftResult.state, ...
                    historical.leftResult.state, "AbsTol", 2e-12);
                testCase.verifyEqual(general.rightResult.state, ...
                    historical.rightResult.state, "AbsTol", 2e-12);
            end
        end

        function supportsRearAxle(testCase)
            axle = translationAxleFixture("REAR");
            result = fsd.kinematics.solveAxleTravel(axle, [8,-6], "mm");
            testCase.verifyTrue(result.converged, result.failureReason);
            testCase.verifyEqual(result.axleIdentity.axleId, "REAR");
            testCase.verifyEqual(result.leftResult.geometryIdentity.cornerId, "RL");
            testCase.verifyEqual(result.rightResult.geometryIdentity.cornerId, "RR");
        end

        function asymmetricSweepPreservesRequestedOrder(testCase)
            axle = analyticAxleFixture(false);
            pairs_mm = [15,-10; -12,8; 20,5; 0,0];
            sweep = fsd.kinematics.solveAxleTravelSweep(axle, pairs_mm, "mm");
            testCase.verifyTrue(sweep.allConverged);
            testCase.verifyTrue( ...
                fsd.kinematics.validateAxleTravelSweepResult(sweep));
            testCase.verifyEqual(sweep.requestedWheelTravel_m, ...
                pairs_mm/1000, "AbsTol", 1e-15);
            testCase.verifyEqual(sweep.results(2).requestedWheelTravel_m, ...
                pairs_mm(2,:)/1000, "AbsTol", 1e-15);
        end

        function failureRemainsBilateralAndExplicit(testCase)
            axle = analyticAxleFixture(false);
            result = fsd.kinematics.solveAxleTravel(axle, [500,0], "mm");
            testCase.verifyFalse(result.converged);
            testCase.verifyEqual(result.status, "NO_CONVERGENCE");
            testCase.verifyFalse(result.leftConverged);
            testCase.verifyTrue(result.rightConverged);
        end

        function rejectsInvalidPairShape(testCase)
            axle = analyticAxleFixture(false);
            testCase.verifyError(@() fsd.kinematics.solveAxleTravel( ...
                axle, [1,2,3], "mm"), "fsd:kinematics:InvalidWheelTravel");
        end

        function rejectsTamperedIdentity(testCase)
            axle = analyticAxleFixture(false);
            result = fsd.kinematics.solveAxleTravel(axle, [5,-5], "mm");
            result.axleIdentity.axleId = "REAR";
            testCase.verifyError(@() ...
                fsd.kinematics.validateAxleTravelResult(result), ...
                "fsd:kinematics:InvalidAxleTravelResult");
        end
    end
end
