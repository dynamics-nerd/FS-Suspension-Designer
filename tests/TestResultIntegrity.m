classdef TestResultIntegrity < matlab.unittest.TestCase
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
        function resultAndSweepCarryCanonicalGeometryIdentity(testCase)
            geometry = testCase.analysisGeometry();
            result = fsd.kinematics.solveBump(geometry, 10, "mm");
            sweep = fsd.kinematics.solveBumpSweep( ...
                geometry, [5; 10], "mm");
            expected = fsd.model.geometryIdentity(geometry);
            stateAnalysis = fsd.analysis.analyzeCornerState(geometry, result);
            sweepAnalysis = fsd.analysis.analyzeBumpSweep(geometry, sweep);

            testCase.verifyEqual(result.schemaVersion, "0.3.0");
            testCase.verifyEqual(sweep.schemaVersion, "0.3.0");
            testCase.verifyEqual(result.geometryIdentity, expected);
            testCase.verifyEqual(sweep.geometryIdentity, expected);
            testCase.verifyEqual(stateAnalysis.geometryIdentity, expected);
            testCase.verifyEqual(sweepAnalysis.geometryIdentity, expected);
            testCase.verifyTrue( ...
                fsd.kinematics.validateKinematicResult(result));
            testCase.verifyTrue( ...
                fsd.kinematics.validateBumpSweepResult(sweep));
        end

        function rejectsSweepFromSubtlyDifferentGeometry(testCase)
            geometryA = testCase.analysisGeometry();
            geometryB = testCase.perturbGeometry(geometryA, 1e-6);
            sweepA = fsd.kinematics.solveBumpSweep( ...
                geometryA, [5; 10; 15], "mm");

            testCase.verifyError(@() fsd.analysis.analyzeBumpSweep( ...
                geometryB, sweepA), "fsd:analysis:GeometryMismatch");
        end

        function rejectsCornerStateFromDifferentGeometry(testCase)
            geometryA = testCase.analysisGeometry();
            geometryB = testCase.perturbGeometry(geometryA, -1e-6);
            resultA = fsd.kinematics.solveBump(geometryA, 10, "mm");

            testCase.verifyError(@() fsd.analysis.analyzeCornerState( ...
                geometryB, resultA), "fsd:analysis:GeometryMismatch");
        end

        function rejectsForgedIdentityForExternalConstraints(testCase)
            geometryA = testCase.analysisGeometry();
            resultA = fsd.kinematics.solveBump(geometryA, 10, "mm");
            roles = ["UCA_FWD_CHASSIS"; "LCA_AFT_CHASSIS"; ...
                "TIE_ROD_INBOARD"];
            components = [3; 3; 3];

            for index = 1:numel(roles)
                geometryB = testCase.perturbHardpoint(geometryA, ...
                    roles(index), components(index), 1e-6);
                forged = resultA;
                forged.geometryIdentity = ...
                    fsd.model.geometryIdentity(geometryB);
                testCase.verifyError(@() ...
                    fsd.kinematics.validateKinematicResult(forged), ...
                    "fsd:kinematics:InvalidKinematicResult", ...
                    sprintf("Forged identity was accepted for %s.", ...
                    roles(index)));
            end
        end

        function rejectsSweepWithForgedIdentities(testCase)
            geometryA = testCase.analysisGeometry();
            geometryB = testCase.perturbHardpoint( ...
                geometryA, "UCA_FWD_CHASSIS", 3, 1e-6);
            sweep = fsd.kinematics.solveBumpSweep( ...
                geometryA, [5; 10; 15], "mm");
            forgedIdentity = fsd.model.geometryIdentity(geometryB);
            sweep.geometryIdentity = forgedIdentity;
            for index = 1:numel(sweep.results)
                sweep.results(index).geometryIdentity = forgedIdentity;
            end

            testCase.verifyError(@() ...
                fsd.kinematics.validateBumpSweepResult(sweep), ...
                "fsd:kinematics:InvalidBumpSweepResult");
        end

        function rejectsContradictoryConvergedStatuses(testCase)
            geometry = testCase.analysisGeometry();
            result = fsd.kinematics.solveBump(geometry, 0, "mm");

            result.status = "NO_CONVERGENCE";
            testCase.verifyError(@() fsd.analysis.analyzeCornerState( ...
                geometry, result), "fsd:analysis:InvalidKinematicResult");
            result.status = "NOT_ATTEMPTED";
            testCase.verifyError(@() fsd.analysis.analyzeCornerState( ...
                geometry, result), "fsd:analysis:InvalidKinematicResult");
        end

        function rejectsUnknownStatuses(testCase)
            geometry = testCase.analysisGeometry();
            converged = fsd.kinematics.solveBump(geometry, 0, "mm");
            converged.status = "UNKNOWN";
            testCase.verifyError(@() ...
                fsd.kinematics.validateKinematicResult(converged), ...
                "fsd:kinematics:InvalidKinematicResult");

            failed = fsd.kinematics.solveBump(geometry, 500, "mm");
            failed.status = "UNKNOWN";
            testCase.verifyError(@() ...
                fsd.kinematics.validateKinematicResult(failed), ...
                "fsd:kinematics:InvalidKinematicResult");
        end

        function statusAndAttemptedFollowSolverExecution(testCase)
            geometry = testCase.analysisGeometry();
            sweep = fsd.kinematics.solveBumpSweep( ...
                geometry, [0; 20; 500; 10; -10], "mm");
            statuses = reshape(string({sweep.results.status}), [], 1);
            attempted = reshape( ...
                arrayfun(@(item) item.diagnostics.attempted, ...
                sweep.results), [], 1);
            tailDiagnostics = [sweep.results(4:5).diagnostics];

            testCase.verifyEqual(statuses, [ ...
                "CONVERGED"; "CONVERGED"; "NO_CONVERGENCE"; ...
                "NOT_ATTEMPTED"; "NOT_ATTEMPTED"]);
            testCase.verifyEqual(attempted, ...
                [true; true; true; false; false]);
            testCase.verifyEqual( ...
                [tailDiagnostics.iterations], [0, 0]);
            testCase.verifyEqual( ...
                [tailDiagnostics.functionEvaluations], ...
                [0, 0]);
            testCase.verifyEqual( ...
                [tailDiagnostics.continuationSteps], [0, 0]);
            testCase.verifyTrue( ...
                fsd.kinematics.validateBumpSweepResult(sweep));
        end

        function rejectsStatusAttemptedContradictions(testCase)
            geometry = testCase.analysisGeometry();
            sweep = fsd.kinematics.solveBumpSweep( ...
                geometry, [0; 500; 10], "mm");
            noConvergence = sweep.results(2);
            notAttempted = sweep.results(3);

            invalidNoConvergence = noConvergence;
            invalidNoConvergence.diagnostics.attempted = false;
            testCase.verifyError(@() ...
                fsd.kinematics.validateKinematicResult( ...
                invalidNoConvergence), ...
                "fsd:kinematics:InvalidKinematicResult");

            invalidNotAttempted = notAttempted;
            invalidNotAttempted.diagnostics.attempted = true;
            testCase.verifyError(@() ...
                fsd.kinematics.validateKinematicResult(invalidNotAttempted), ...
                "fsd:kinematics:InvalidKinematicResult");

            swappedStatus = noConvergence;
            swappedStatus.status = "NOT_ATTEMPTED";
            testCase.verifyError(@() ...
                fsd.kinematics.validateKinematicResult(swappedStatus), ...
                "fsd:kinematics:InvalidKinematicResult");

            swappedStatus = notAttempted;
            swappedStatus.status = "NO_CONVERGENCE";
            testCase.verifyError(@() ...
                fsd.kinematics.validateKinematicResult(swappedStatus), ...
                "fsd:kinematics:InvalidKinematicResult");
        end

        function rejectsFinitePayloadOnFailedResult(testCase)
            geometry = testCase.analysisGeometry();
            failed = fsd.kinematics.solveBump(geometry, 500, "mm");
            converged = fsd.kinematics.solveBump(geometry, 0, "mm");
            failed.achievedWheelTravel_m = converged.achievedWheelTravel_m;
            failed.state = converged.state;
            failed.uprightPose = converged.uprightPose;
            failed.wheelAxis = converged.wheelAxis;
            failed.camber_rad = converged.camber_rad;

            testCase.verifyError(@() ...
                fsd.kinematics.validateKinematicResult(failed), ...
                "fsd:kinematics:InvalidKinematicResult");
        end

        function rejectsIncompleteSuspensionState(testCase)
            geometry = testCase.analysisGeometry();
            result = fsd.kinematics.solveBump(geometry, 0, "mm");
            result.state = struct( ...
                "ubj_m", result.state.ubj_m, ...
                "lbj_m", result.state.lbj_m);

            testCase.verifyError(@() ...
                fsd.kinematics.validateKinematicResult(result), ...
                "fsd:kinematics:InvalidSuspensionState");
        end

        function rejectsRedundantStateContradiction(testCase)
            geometry = testCase.analysisGeometry();
            result = fsd.kinematics.solveBump(geometry, 10, "mm");
            result.state.ubj_m(1) = result.state.ubj_m(1) + 1e-5;

            testCase.verifyError(@() ...
                fsd.kinematics.validateKinematicResult(result), ...
                "fsd:kinematics:InvalidSuspensionState");
        end

        function rejectsResultStateWheelAxisContradiction(testCase)
            geometry = testCase.analysisGeometry();
            result = fsd.kinematics.solveBump(geometry, 10, "mm");
            alteredAxis = result.wheelAxis + [1e-4, 0, 0];
            result.wheelAxis = alteredAxis ./ norm(alteredAxis, 2);

            testCase.verifyError(@() ...
                fsd.kinematics.validateKinematicResult(result), ...
                "fsd:kinematics:InvalidKinematicResult");
        end

        function rejectsMultirowCharCorners(testCase)
            invalidCorner = char('FL', 'FR');
            testCase.verifyError(@() ...
                fsd.analysis.camberFromWheelAxis([0, -1, 0], invalidCorner), ...
                "fsd:analysis:InvalidCorner");
            testCase.verifyError(@() ...
                fsd.analysis.toeFromWheelAxis([0, -1, 0], invalidCorner), ...
                "fsd:analysis:InvalidCorner");
            testCase.verifyError(@() fsd.analysis.kingpinInclination( ...
                [0, 0, 1], invalidCorner), "fsd:analysis:InvalidCorner");
            testCase.verifyError(@() ...
                fsd.kinematics.camberFromWheelAxis( ...
                [0, -1, 0], invalidCorner), "fsd:model:InvalidCorner");
        end

        function camberApisShareCanonicalGeometryImplementation(testCase)
            angle = 6 * pi / 180;
            axes = [ ...
                0, -1, 0; ...
                0, -cos(angle), -sin(angle); ...
                0, -cos(angle), sin(angle); ...
                0, 1, 0; ...
                0, cos(angle), -sin(angle); ...
                0, cos(angle), sin(angle)];
            corners = ["FL"; "FL"; "FL"; "FR"; "FR"; "FR"];
            for index = 1:size(axes, 1)
                geometryValue = fsd.geometry.camberFromWheelAxis( ...
                    axes(index, :), corners(index));
                kinematicsValue = fsd.kinematics.camberFromWheelAxis( ...
                    axes(index, :), corners(index));
                analysisValue = fsd.analysis.camberFromWheelAxis( ...
                    axes(index, :), corners(index));
                testCase.verifyEqual(kinematicsValue, geometryValue, ...
                    "AbsTol", 1e-14);
                testCase.verifyEqual(analysisValue, geometryValue, ...
                    "AbsTol", 1e-14);
            end
        end

        function positiveOnlySweepUsesStaticToe(testCase)
            testCase.verifyNoZeroSweep([5; 10; 15; 20]);
        end

        function splitSignSweepUsesStaticToe(testCase)
            testCase.verifyNoZeroSweep([-30; -20; -10; 10; 20; 30]);
        end

        function negativeOnlySweepUsesStaticToe(testCase)
            testCase.verifyNoZeroSweep([-30; -20; -10]);
        end
    end

    methods (Access = private)
        function verifyNoZeroSweep(testCase, travel_mm)
            geometry = testCase.analysisGeometry();
            sweep = fsd.kinematics.solveBumpSweep( ...
                geometry, travel_mm, "mm");
            analysis = fsd.analysis.analyzeBumpSweep(geometry, sweep);
            staticToe_rad = fsd.analysis.toeFromWheelAxis( ...
                geometry.wheel.wheelAxis, geometry.cornerId);
            [~, closestIndex] = min(abs(travel_mm));

            testCase.verifyTrue(analysis.allConverged);
            testCase.verifyEqual(analysis.staticToe_rad, staticToe_rad, ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(analysis.bumpSteer_rad, ...
                analysis.toe_rad - staticToe_rad, "AbsTol", 1e-14);
            testCase.verifyGreaterThan(abs(analysis.bumpSteer_rad(1)), 1e-4);
            testCase.verifyGreaterThan( ...
                abs(analysis.bumpSteer_rad(closestIndex)), 1e-4);
        end
    end

    methods (Static, Access = private)
        function geometry = analysisGeometry()
            corner = "FL";
            ids = corner + "_" + fsd.model.requiredHardpointRoles();
            xyz_m = [ ...
                -0.100, -0.300, 0.400; ...
                 0.100, -0.300, 0.400; ...
                 0.000, -0.600, 0.400; ...
                -0.100, -0.300, 0.100; ...
                 0.100, -0.300, 0.100; ...
                 0.000, -0.600, 0.100; ...
                 0.050, -0.300, 0.200; ...
                 0.050, -0.600, 0.250; ...
                 0.000, -0.650, 0.250; ...
                 0.000, -0.650, 0.000];
            provenance = struct( ...
                "sourceKind", repmat("ASSUMED", 10, 3), ...
                "sourceNote", repmat("Result-integrity fixture", 10, 3));
            staticToe_rad = 2 * pi / 180;
            wheelAxis = [ ...
                -sin(staticToe_rad), -cos(staticToe_rad), 0];
            geometry = fsd.model.createDoubleWishboneGeometry( ...
                corner, ids, xyz_m, "m", wheelAxis, provenance);
        end

        function geometry = perturbGeometry(geometry, delta_m)
            geometry = TestResultIntegrity.perturbHardpoint( ...
                geometry, "UCA_FWD_CHASSIS", 1, delta_m);
        end

        function geometry = perturbHardpoint( ...
                geometry, role, component, delta_m)
            pointId = geometry.cornerId + "_" + role;
            row = geometry.hardpoints.ids == pointId;
            geometry.hardpoints.xyz_m(row, component) = ...
                geometry.hardpoints.xyz_m(row, component) + delta_m;
            fsd.model.validateDoubleWishboneGeometry(geometry);
        end
    end
end
