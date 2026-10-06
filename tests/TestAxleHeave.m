classdef TestAxleHeave < matlab.unittest.TestCase
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
        function solvesAndValidatesSymmetricHeave(testCase)
            axle = analyticAxleFixture(false);
            result = fsd.kinematics.solveAxleHeave(axle, 10, "mm");
            testCase.verifyTrue(result.converged, result.failureReason);
            testCase.verifyTrue( ...
                fsd.kinematics.validateAxleKinematicResult(result));
            testCase.verifyEqual( ...
                result.leftResult.achievedWheelTravel_m, 0.010, ...
                "AbsTol", 2e-9);
            testCase.verifyEqual( ...
                result.rightResult.achievedWheelTravel_m, 0.010, ...
                "AbsTol", 2e-9);
        end

        function sweepPreservesBothSidesAndSymmetry(testCase)
            axle = analyticAxleFixture(false);
            travel_mm = (-20:5:20)';
            sweep = fsd.kinematics.solveAxleHeaveSweep( ...
                axle, travel_mm, "mm");
            analysis = fsd.analysis.analyzeAxleHeaveSweep(axle, sweep);
            testCase.verifyTrue(sweep.allConverged);
            testCase.verifyTrue( ...
                fsd.kinematics.validateAxleHeaveSweepResult(sweep));
            testCase.verifyEqual(sweep.leftConverged, ...
                sweep.rightConverged);
            testCase.verifyEqual(analysis.rollCenterY_m, ...
                zeros(size(travel_mm)), "AbsTol", 2e-8);
            testCase.verifyTrue(all(isfinite(analysis.rollCenterZ_m)));
            testCase.verifyTrue(all(isfinite(analysis.rollCenterHeight_m)));
        end

        function rejectsResultFromDifferentAxle(testCase)
            axleA = analyticAxleFixture(false);
            axleB = analyticAxleFixture(true);
            resultA = fsd.kinematics.solveAxleHeave(axleA, 0, "mm");
            testCase.verifyError(@() ...
                fsd.analysis.analyzeAxleState(axleB, resultA), ...
                "fsd:analysis:AxleGeometryMismatch");
        end

        function unequalDynamicContactLevelsDoNotInventHeight(testCase)
            axle = analyticAxleFixture(true);
            result = fsd.kinematics.solveAxleHeave(axle, 10, "mm");
            testCase.assertTrue(result.converged, result.failureReason);
            analysis = fsd.analysis.analyzeAxleState(axle, result);
            testCase.verifyEqual(analysis.rollCenterHeightStatus, ...
                "CONTACT_LEVEL_MISMATCH");
            testCase.verifyTrue(isnan(analysis.rollCenterHeight_m));
            testCase.verifyTrue(isfinite(analysis.rollCenterZ_m));
        end

        function rejectsSwappedCornerResults(testCase)
            axle = analyticAxleFixture(false);
            result = fsd.kinematics.solveAxleHeave(axle, 0, "mm");
            temporary = result.leftResult;
            result.leftResult = result.rightResult;
            result.rightResult = temporary;
            testCase.verifyError(@() ...
                fsd.kinematics.validateAxleKinematicResult(result), ...
                "fsd:kinematics:InvalidAxleKinematicResult");
        end

        function rejectsMixedSweepIdentity(testCase)
            axleA = analyticAxleFixture(false);
            axleB = analyticAxleFixture(true);
            sweep = fsd.kinematics.solveAxleHeaveSweep( ...
                axleA, [0; 5], "mm");
            sweep.axleIdentity = fsd.model.axleIdentity(axleB);
            testCase.verifyError(@() ...
                fsd.kinematics.validateAxleHeaveSweepResult(sweep), ...
                "fsd:kinematics:InvalidAxleHeaveSweepResult");
        end

        function nonconvergedPointsDoNotPublishRollCenter(testCase)
            axle = analyticAxleFixture(false);
            sweep = fsd.kinematics.solveAxleHeaveSweep( ...
                axle, [0; 500; 5], "mm");
            analysis = fsd.analysis.analyzeAxleHeaveSweep(axle, sweep);
            testCase.verifyEqual(sweep.status, ...
                ["CONVERGED"; "NO_CONVERGENCE"; "NOT_ATTEMPTED"]);
            testCase.verifyTrue(all(isnan(analysis.rollCenterZ_m(2:3))));
            testCase.verifyEqual(analysis.status(2:3), ...
                ["KINEMATICS_NOT_CONVERGED"; ...
                "KINEMATICS_NOT_CONVERGED"]);
            testCase.verifyTrue(all(isnan( ...
                analysis.states(2).left.geometricContact.point_m)));
            testCase.verifyTrue(all(isnan(analysis.states(2).left. ...
                geometricContact.wheelCenter_m)));
            testCase.verifyTrue(all(isnan(analysis.states(2).left. ...
                geometricContact.wheelAxis)));
            testCase.verifyTrue(all(isnan(analysis.states(2).left. ...
                geometricContact.staticDatum_m)));
            testCase.verifyTrue(all(isnan(analysis.states(2).left. ...
                instantCenter.upperConstraint.pivotAxisPoint_m)));
            testCase.verifyTrue(all(isnan(analysis.states(2). ...
                rollCenterHomogeneousPoint)));
            testCase.verifyTrue(all(isnan(analysis.states(2).left. ...
                rollCenterConstructionLine.coefficients)));
        end

        function plotsMigrationCurves(testCase)
            axle = analyticAxleFixture(false);
            sweep = fsd.kinematics.solveAxleHeaveSweep( ...
                axle, (-10:5:10)', "mm");
            analysis = fsd.analysis.analyzeAxleHeaveSweep(axle, sweep);
            figureHandle = figure("Visible", "off");
            testCase.addTeardown(@() closeIfValid(figureHandle));
            handles = fsd.analysis.plotRollCenterMigration( ...
                analysis, figureHandle);
            testCase.verifyEqual(numel(handles.axes), 3);
            testCase.verifyTrue(all(isgraphics(handles.lines)));
            testCase.verifyEqual(handles.lines(1).XData(:), ...
                (-10:5:10)', "AbsTol", 1e-12);
        end
    end
end

function closeIfValid(figureHandle)
if isgraphics(figureHandle, "figure")
    close(figureHandle);
end
end
