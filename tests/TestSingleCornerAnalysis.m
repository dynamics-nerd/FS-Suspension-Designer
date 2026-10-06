classdef TestSingleCornerAnalysis < matlab.unittest.TestCase
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
        function nominalToeIsZeroOnBothSides(testCase)
            testCase.verifyEqual( ...
                fsd.analysis.toeFromWheelAxis([0, -1, 0], "FL"), 0);
            testCase.verifyEqual( ...
                fsd.analysis.toeFromWheelAxis([0, 1, 0], "FR"), 0);
        end

        function toeSignIsSideIndependent(testCase)
            angle = 4 * pi / 180;
            flToeIn = [-sin(angle), -cos(angle), 0];
            frToeIn = [-sin(angle), cos(angle), 0];
            flToeOut = [sin(angle), -cos(angle), 0];
            frToeOut = [sin(angle), cos(angle), 0];

            testCase.verifyEqual( ...
                fsd.analysis.toeFromWheelAxis(flToeIn, "FL"), ...
                angle, "AbsTol", 1e-14);
            testCase.verifyEqual( ...
                fsd.analysis.toeFromWheelAxis(frToeIn, "FR"), ...
                angle, "AbsTol", 1e-14);
            testCase.verifyEqual( ...
                fsd.analysis.toeFromWheelAxis(flToeOut, "FL"), ...
                -angle, "AbsTol", 1e-14);
            testCase.verifyEqual( ...
                fsd.analysis.toeFromWheelAxis(frToeOut, "FR"), ...
                -angle, "AbsTol", 1e-14);
        end

        function camberDoesNotCreateFalseToe(testCase)
            toe = 3 * pi / 180;
            camber = 11 * pi / 180;
            horizontalScale = cos(camber);
            flAxis = [-sin(toe) * horizontalScale, ...
                -cos(toe) * horizontalScale, sin(camber)];
            frAxis = [-sin(toe) * horizontalScale, ...
                cos(toe) * horizontalScale, sin(camber)];

            testCase.verifyEqual( ...
                fsd.analysis.toeFromWheelAxis(flAxis, "FL"), ...
                toe, "AbsTol", 1e-14);
            testCase.verifyEqual( ...
                fsd.analysis.toeFromWheelAxis(frAxis, "FR"), ...
                toe, "AbsTol", 1e-14);
        end

        function steeringAxisRunsFromLowerToUpper(testCase)
            actual = fsd.analysis.steeringAxisFromPoints( ...
                [0.1, 0.2, 0.3], [0.2, 0.2, 0.5]);
            expected = [0.1, 0, 0.2] / norm([0.1, 0, 0.2]);
            testCase.verifyEqual(actual, expected, "AbsTol", 1e-14);
        end

        function casterUsesRearwardPositiveX(testCase)
            angle = 7 * pi / 180;
            positiveAxis = [sin(angle), 0, cos(angle)];
            negativeAxis = [-sin(angle), 0, cos(angle)];

            testCase.verifyEqual( ...
                fsd.analysis.casterFromSteeringAxis(positiveAxis), ...
                angle, "AbsTol", 1e-14);
            testCase.verifyEqual( ...
                fsd.analysis.casterFromSteeringAxis(negativeAxis), ...
                -angle, "AbsTol", 1e-14);
        end

        function casterDoesNotForcePositiveVerticalAxis(testCase)
            angle = 170 * pi / 180;
            axis = [sin(angle), 0, cos(angle)];
            testCase.verifyEqual( ...
                fsd.analysis.casterFromSteeringAxis(axis), ...
                angle, "AbsTol", 1e-14);
        end

        function kingpinInclinationIsSideIndependent(testCase)
            angle = 8 * pi / 180;
            flInward = [0, sin(angle), cos(angle)];
            frInward = [0, -sin(angle), cos(angle)];
            flOutward = [0, -sin(angle), cos(angle)];
            frOutward = [0, sin(angle), cos(angle)];

            testCase.verifyEqual( ...
                fsd.analysis.kingpinInclination(flInward, "FL"), ...
                angle, "AbsTol", 1e-14);
            testCase.verifyEqual( ...
                fsd.analysis.kingpinInclination(frInward, "FR"), ...
                angle, "AbsTol", 1e-14);
            testCase.verifyEqual( ...
                fsd.analysis.kingpinInclination(flOutward, "FL"), ...
                -angle, "AbsTol", 1e-14);
            testCase.verifyEqual( ...
                fsd.analysis.kingpinInclination(frOutward, "FR"), ...
                -angle, "AbsTol", 1e-14);
        end

        function rejectsInvalidAnalysisInputs(testCase)
            testCase.verifyError(@() fsd.analysis.toeFromWheelAxis( ...
                [0, NaN, 0], "FL"), "fsd:analysis:InvalidWheelAxis");
            testCase.verifyError(@() fsd.analysis.toeFromWheelAxis( ...
                [0, -2, 0], "FL"), "fsd:analysis:NonUnitWheelAxis");
            testCase.verifyError(@() fsd.analysis.toeFromWheelAxis( ...
                [0, -1, 0], "XX"), "fsd:analysis:InvalidCorner");
            testCase.verifyError(@() fsd.analysis.steeringAxisFromPoints( ...
                [0, 0, 0], [0, 0, 0]), ...
                "fsd:analysis:DegenerateSteeringAxis");
            testCase.verifyError(@() fsd.analysis.casterFromSteeringAxis( ...
                [0, 1, 0]), "fsd:analysis:DegenerateCasterProjection");
            testCase.verifyError(@() fsd.analysis.kingpinInclination( ...
                [1, 0, 0], "FL"), ...
                "fsd:analysis:DegenerateKingpinProjection");
        end

        function benchmarkHasConstantToeAndZeroBumpSteer(testCase)
            staticToe = 3 * pi / 180;
            geometry = testCase.benchmarkGeometry(staticToe, false);
            sweep = fsd.kinematics.solveBumpSweep( ...
                geometry, (-30:5:30)', "mm");
            analysis = fsd.analysis.analyzeBumpSweep(geometry, sweep);

            testCase.verifyTrue(analysis.allConverged);
            testCase.verifyEqual(analysis.staticToe_rad, staticToe, ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(analysis.toe_rad, ...
                repmat(staticToe, 13, 1), "AbsTol", 2e-8);
            testCase.verifyEqual(analysis.bumpSteer_rad, zeros(13, 1), ...
                "AbsTol", 2e-8);
        end

        function analyzesOneConvergedState(testCase)
            geometry = testCase.benchmarkGeometry(0, true);
            result = fsd.kinematics.solveBump(geometry, 10, "mm");
            analysis = fsd.analysis.analyzeCornerState(geometry, result);

            testCase.verifyEqual(analysis.kind, ...
                "CornerKinematicAnalysis");
            testCase.verifyEqual(analysis.wheelTravel_m, 0.010, ...
                "AbsTol", 2e-9);
            testCase.verifyTrue(analysis.converged);
            testCase.verifyEqual(analysis.status, "CONVERGED");
            testCase.verifyEqual(norm(analysis.steeringAxis), 1, ...
                "AbsTol", 1e-12);
        end

        function modifiedGeometryProducesSignedContinuousBumpSteer(testCase)
            geometry = testCase.benchmarkGeometry(0, true);
            travel_mm = (-20:5:20)';
            sweep = fsd.kinematics.solveBumpSweep( ...
                geometry, travel_mm, "mm");
            analysis = fsd.analysis.analyzeBumpSweep(geometry, sweep);
            zeroIndex = find(travel_mm == 0);

            testCase.verifyTrue(analysis.allConverged);
            testCase.verifyEqual(analysis.bumpSteer_rad(zeroIndex), 0, ...
                "AbsTol", 1e-14);
            testCase.verifyGreaterThan( ...
                analysis.bumpSteer_rad(travel_mm < 0), zeros(4, 1));
            testCase.verifyLessThan( ...
                analysis.bumpSteer_rad(travel_mm > 0), zeros(4, 1));
            testCase.verifyLessThan(max(abs(diff(analysis.toe_rad))), ...
                1.1 * pi / 180);
        end

        function reflectedSweepsPreserveAllMetrics(testCase)
            leftGeometry = testCase.benchmarkGeometry(2 * pi / 180, true);
            rightGeometry = fsd.geometry.reflectDoubleWishboneGeometry( ...
                leftGeometry);
            travel_mm = (-20:5:20)';
            left = fsd.analysis.analyzeBumpSweep(leftGeometry, ...
                fsd.kinematics.solveBumpSweep( ...
                leftGeometry, travel_mm, "mm"));
            right = fsd.analysis.analyzeBumpSweep(rightGeometry, ...
                fsd.kinematics.solveBumpSweep( ...
                rightGeometry, travel_mm, "mm"));

            fields = ["camber_rad", "toe_rad", "bumpSteer_rad", ...
                "caster_rad", "kingpinInclination_rad"];
            for index = 1:numel(fields)
                testCase.verifyEqual(right.(fields(index)), ...
                    left.(fields(index)), "AbsTol", 2e-8);
            end
            testCase.verifyEqual(right.steeringAxis(:, [1, 3]), ...
                left.steeringAxis(:, [1, 3]), "AbsTol", 2e-8);
            testCase.verifyEqual(right.steeringAxis(:, 2), ...
                -left.steeringAxis(:, 2), "AbsTol", 2e-8);
        end

        function sweepPreservesOrderAndFailureStatus(testCase)
            geometry = testCase.benchmarkGeometry(0, false);
            sweep = fsd.kinematics.solveBumpSweep( ...
                geometry, [0; 500; 5], "mm");
            analysis = fsd.analysis.analyzeBumpSweep(geometry, sweep);

            testCase.verifyEqual(analysis.requestedWheelTravel_m, ...
                [0; 0.5; 0.005]);
            testCase.verifyEqual(numel(analysis.states), 3);
            testCase.verifyTrue(analysis.converged(1));
            testCase.verifyFalse(analysis.converged(2));
            testCase.verifyEqual(analysis.status, ...
                ["CONVERGED"; "NO_CONVERGENCE"; "NOT_ATTEMPTED"]);
            testCase.verifyTrue(all(isnan(analysis.wheelTravel_m(2:3))));
            testCase.verifyTrue(all(isnan(analysis.camber_rad(2:3))));
            testCase.verifyTrue(all(isnan(analysis.toe_rad(2:3))));
            testCase.verifyTrue(all(isnan(analysis.bumpSteer_rad(2:3))));
            testCase.verifyTrue(all(isnan(analysis.caster_rad(2:3))));
            testCase.verifyTrue( ...
                all(isnan(analysis.kingpinInclination_rad(2:3))));
        end

        function plotsFiveAnalysisCurves(testCase)
            geometry = testCase.benchmarkGeometry(0, true);
            sweep = fsd.kinematics.solveBumpSweep( ...
                geometry, (-10:5:10)', "mm");
            analysis = fsd.analysis.analyzeBumpSweep(geometry, sweep);
            figureHandle = figure("Visible", "off");
            testCase.addTeardown(@() closeIfValid(figureHandle));

            handles = fsd.analysis.plotBumpSweepAnalysis( ...
                analysis, figureHandle);

            testCase.verifyEqual(numel(handles.axes), 5);
            testCase.verifyTrue(all(isgraphics(handles.axes, "axes")));
            testCase.verifyTrue(all(isgraphics(handles.lines)));
            testCase.verifyEqual(handles.lines(1).XData(:), ...
                analysis.wheelTravel_m * 1000, "AbsTol", 1e-12);
        end

        function rejectsInconsistentOrInfiniteResultData(testCase)
            geometry = testCase.benchmarkGeometry(0, false);
            result = fsd.kinematics.solveBump(geometry, 0, "mm");
            result.wheelAxis(1) = Inf;
            testCase.verifyError(@() fsd.analysis.analyzeCornerState( ...
                geometry, result), ...
                "fsd:analysis:InvalidKinematicResult");

            sweep = fsd.kinematics.solveBumpSweep( ...
                geometry, [0; 5], "mm");
            sweep.results(2).requestedWheelTravel_m = 0.006;
            testCase.verifyError(@() fsd.analysis.analyzeBumpSweep( ...
                geometry, sweep), "fsd:analysis:InvalidBumpSweep");
        end
    end

    methods (Static, Access = private)
        function geometry = benchmarkGeometry(staticToe_rad, offsetTieRod)
            corner = "FL";
            ids = corner + "_" + fsd.model.requiredHardpointRoles();
            tieRodInboardZ_m = 0.250;
            if offsetTieRod
                tieRodInboardZ_m = 0.200;
            end
            xyz_m = [ ...
                -0.100, -0.300, 0.400; ...
                 0.100, -0.300, 0.400; ...
                 0.000, -0.600, 0.400; ...
                -0.100, -0.300, 0.100; ...
                 0.100, -0.300, 0.100; ...
                 0.000, -0.600, 0.100; ...
                 0.050, -0.300, tieRodInboardZ_m; ...
                 0.050, -0.600, 0.250; ...
                 0.000, -0.650, 0.250; ...
                 0.000, -0.650, 0.000];
            provenance = struct( ...
                "sourceKind", repmat("ASSUMED", 10, 3), ...
                "sourceNote", repmat("Analytic analysis fixture", 10, 3));
            wheelAxis = [-sin(staticToe_rad), -cos(staticToe_rad), 0];
            geometry = fsd.model.createDoubleWishboneGeometry( ...
                corner, ids, xyz_m, "m", wheelAxis, provenance);
        end
    end
end

function closeIfValid(figureHandle)
if isgraphics(figureHandle, "figure")
    close(figureHandle);
end
end
