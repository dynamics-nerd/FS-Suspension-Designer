classdef TestActuationKinematics < matlab.unittest.TestCase
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
            [geometry, actuation] = actuationFixture();
            source = fsd.kinematics.solveBump(geometry, 0, "m");
            result = fsd.kinematics.solveActuation(actuation, source);
            testCase.verifyTrue(result.converged, result.failureReason);
            testCase.verifyEqual(result.rockerAngle_rad, 0, "AbsTol", 1e-14);
            testCase.verifyEqual(result.damperCompression_m, 0, ...
                "AbsTol", 1e-14);
            testCase.verifyEqual(result.actuationRodLengthResidual_m, 0, ...
                "AbsTol", 1e-14);
        end

        function uprightAttachmentUsesExactPose(testCase)
            [geometry, actuation] = actuationFixture();
            source = fsd.kinematics.solveBump(geometry, 15, "mm");
            result = fsd.kinematics.solveActuation(actuation, source);
            expected = fsd.geometry.transformPointsRigid( ...
                actuation.suspensionAttachment.pointStatic_m, ...
                source.uprightPose.referencePointStatic_m, ...
                source.uprightPose.translation_m, ...
                source.uprightPose.rotationMatrix);
            testCase.verifyEqual(result.suspensionAttachmentCurrent_m, ...
                expected, "AbsTol", 1e-13);
        end

        function ucaAttachmentRigidInvariants(testCase)
            testCase.verifyWishboneAttachment("UCA", 12);
        end

        function lcaAttachmentRigidInvariants(testCase)
            testCase.verifyWishboneAttachment("LCA", -12);
        end

        function yzRockerPreservesAxialCoordinate(testCase)
            [geometry, actuation] = actuationFixture("YZ_PLANE");
            source = fsd.kinematics.solveBump(geometry, 15, "mm");
            result = fsd.kinematics.solveActuation(actuation, source);
            testCase.verifyTrue(result.converged, result.failureReason);
            testCase.verifyEqual(result.rockerRodPointCurrent_m(1), ...
                actuation.rocker.actuationRodPoint.pointStatic_m(1), ...
                "AbsTol", 1e-14);
            testCase.verifyRockerRigidity(actuation, result);
        end

        function xzRockerPreservesAxialCoordinate(testCase)
            [geometry, actuation] = actuationFixture("XZ_PLANE");
            source = fsd.kinematics.solveBump(geometry, 10, "mm");
            result = fsd.kinematics.solveActuation(actuation, source);
            testCase.verifyTrue(result.converged, result.failureReason);
            testCase.verifyEqual(result.rockerRodPointCurrent_m(2), ...
                actuation.rocker.actuationRodPoint.pointStatic_m(2), ...
                "AbsTol", 1e-14);
            testCase.verifyRockerRigidity(actuation, result);
        end

        function customTiltedRockerIsRigid(testCase)
            [geometry, actuation] = actuationFixture("CUSTOM");
            source = fsd.kinematics.solveBump(geometry, 10, "mm");
            result = fsd.kinematics.solveActuation(actuation, source);
            testCase.verifyTrue(result.converged, result.failureReason);
            testCase.verifyRockerRigidity(actuation, result);
            axis = actuation.rocker.axis;
            staticAxial = dot( ...
                actuation.rocker.actuationRodPoint.pointStatic_m - ...
                axis.point_m, axis.direction_unit);
            currentAxial = dot(result.rockerRodPointCurrent_m - ...
                axis.point_m, axis.direction_unit);
            testCase.verifyEqual(currentAxial, staticAxial, ...
                "AbsTol", 1e-14);
        end

        function reversingCustomAxisReversesAngleNotPhysicalPose(testCase)
            [geometry, positive, definition] = actuationFixture("CUSTOM");
            definition.rocker.axis.direction = ...
                -definition.rocker.axis.direction;
            negative = fsd.model.createActuationGeometry( ...
                geometry, definition, "m");
            source = fsd.kinematics.solveBump(geometry, 10, "mm");
            positiveResult = fsd.kinematics.solveActuation(positive, source);
            negativeResult = fsd.kinematics.solveActuation(negative, source);
            testCase.verifyEqual(negativeResult.rockerAngle_rad, ...
                -positiveResult.rockerAngle_rad, "AbsTol", 2e-13);
            testCase.verifyEqual(negativeResult.rockerRodPointCurrent_m, ...
                positiveResult.rockerRodPointCurrent_m, "AbsTol", 2e-13);
            testCase.verifyEqual(negativeResult.damperCompression_m, ...
                positiveResult.damperCompression_m, "AbsTol", 2e-13);
        end

        function pushrodAndPullrodKinematicsAreEquivalent(testCase)
            [geometry, pushrod, definition] = actuationFixture();
            definition.actuationType = "PULLROD";
            pullrod = fsd.model.createActuationGeometry( ...
                geometry, definition, "m");
            source = fsd.kinematics.solveBump(geometry, 12, "mm");
            pushResult = fsd.kinematics.solveActuation(pushrod, source);
            pullResult = fsd.kinematics.solveActuation(pullrod, source);
            testCase.verifyNotEqual(pushResult.actuationIdentity, ...
                pullResult.actuationIdentity);
            testCase.verifyEqual(pushResult.rockerAngle_rad, ...
                pullResult.rockerAngle_rad, "AbsTol", 1e-14);
            testCase.verifyEqual(pushResult.damperCompression_m, ...
                pullResult.damperCompression_m, "AbsTol", 1e-14);
        end

        function sweepMaintainsBranchAndRodClosure(testCase)
            [geometry, actuation] = actuationFixture();
            bump = fsd.kinematics.solveBumpSweep( ...
                geometry, (-20:2:20)', "mm");
            sweep = fsd.kinematics.solveActuationSweep(actuation, bump);
            testCase.verifyTrue(sweep.allConverged);
            testCase.verifyLessThan(max(abs(diff(sweep.rockerAngle_rad))), ...
                0.1);
            residuals = reshape( ...
                [sweep.results.actuationRodLengthResidual_m], [], 1);
            testCase.verifyLessThan(max(abs(residuals)), 1e-12);
        end

        function roundTripsReturnStaticBranch(testCase)
            [geometry, actuation] = actuationFixture();
            paths = {[0;15;0], [0;-15;0]};
            for index = 1:numel(paths)
                bump = fsd.kinematics.solveBumpSweep( ...
                    geometry, paths{index}, "mm");
                sweep = fsd.kinematics.solveActuationSweep(actuation, bump);
                testCase.verifyTrue(sweep.allConverged);
                testCase.verifyEqual(sweep.rockerAngle_rad(end), 0, ...
                    "AbsTol", 1e-12);
                testCase.verifyEqual(sweep.damperCompression_m(end), 0, ...
                    "AbsTol", 1e-12);
            end
        end

        function identifiesBothMathematicalRoots(testCase)
            [geometry, actuation] = actuationFixture();
            source = fsd.kinematics.solveBump(geometry, 8, "mm");
            result = fsd.kinematics.solveActuation(actuation, source);
            testCase.verifyEqual(result.diagnostics.constraintCase, ...
                "TWO_SOLUTIONS");
            testCase.verifyNumElements( ...
                result.diagnostics.candidateAngles_rad, 2);
            candidates = result.diagnostics.candidateAngles_rad;
            testCase.verifyEqual(result.rockerAngle_rad, ...
                candidates(result.diagnostics.selectedCandidateIndex));
            testCase.verifyEqual(abs(result.rockerAngle_rad), ...
                min(abs(candidates)), "AbsTol", 1e-14);
        end

        function continuationUsesPreviousUnwrappedRoot(testCase)
            [geometry, actuation] = actuationFixture();
            source = fsd.kinematics.solveBump(geometry, 0, "m");
            reference = 2*pi;
            result = fsd.kinematics.solveActuation(actuation, source, ...
                struct("ReferenceRockerAngle_rad", reference));
            testCase.verifyEqual(result.rockerAngle_rad, 2*pi, ...
                "AbsTol", 1e-13);
            testCase.verifyEqual(result.rockerAngleWrapped_rad, 0, ...
                "AbsTol", 1e-13);
        end

        function exactTangencyIsValidAndIllConditioned(testCase)
            [geometry, actuation] = actuationFixture( ...
                "YZ_PLANE", "UPRIGHT", "PUSHROD", "TANGENT");
            source = fsd.kinematics.solveBump(geometry, 0, "m");
            result = fsd.kinematics.solveActuation(actuation, source);
            testCase.verifyTrue(result.converged, result.failureReason);
            testCase.verifyEqual(result.diagnostics.constraintCase, "TANGENT");
            testCase.verifyTrue(result.isIllConditioned);
            testCase.verifyEqual(result.conditioning, 0);
            testCase.verifyEqual(result.diagnostics.acosRatio, -1);
            testCase.verifyNumElements(result.diagnostics.candidateAngles_rad, 1);
        end

        function toleranceTangencyOutsideAcosDomainIsAccepted(testCase)
            [geometry, actuation] = actuationFixture( ...
                "YZ_PLANE", "UPRIGHT", "PUSHROD", "TANGENT");
            source = fsd.kinematics.solveBump(geometry, 0, "m");
            for perturbation = [-eps,eps]
                perturbed = actuation;
                perturbed.actuationRod.staticLength_m = ...
                    actuation.actuationRod.staticLength_m + perturbation;
                result = fsd.kinematics.solveActuation(perturbed, source);
                testCase.verifyTrue(result.converged, result.failureReason);
                testCase.verifyEqual( ...
                    result.diagnostics.constraintCase, "TANGENT");
                testCase.verifyEqual(abs(result.diagnostics.acosRatio), 1);
                testCase.verifyEqual(result.conditioning, 0);
                closureResidual_m2 = ...
                    result.diagnostics.constraintA_m2*cos( ...
                    result.rockerAngle_rad) + ...
                    result.diagnostics.constraintB_m2*sin( ...
                    result.rockerAngle_rad) - ...
                    result.diagnostics.constraintD_m2;
                testCase.verifyLessThanOrEqual(abs(closureResidual_m2), ...
                    result.diagnostics.coefficientTolerance_m2);
            end
        end

        function positiveRatioTangencyIsCanonical(testCase)
            [geometry,actuation] = actuationFixture( ...
                "YZ_PLANE","UPRIGHT","PUSHROD","TANGENT_POSITIVE");
            source = fsd.kinematics.solveBump(geometry,0,"m");
            result = fsd.kinematics.solveActuation(actuation,source);
            testCase.verifyTrue(result.converged,result.failureReason);
            testCase.verifyEqual(result.diagnostics.constraintCase,"TANGENT");
            testCase.verifyEqual(result.diagnostics.acosRatio,1);
            testCase.verifyEqual(result.conditioning,0);
        end

        function incompatibleCircleAndSphereReportNoSolution(testCase)
            [geometry, actuation] = actuationFixture( ...
                "YZ_PLANE", "UPRIGHT", "PUSHROD", "TANGENT");
            source = fsd.kinematics.solveBump(geometry, 2, "mm");
            result = fsd.kinematics.solveActuation(actuation, source);
            testCase.verifyFalse(result.converged);
            testCase.verifyEqual(result.status, "NO_ROCKER_SOLUTION");
            testCase.verifyTrue(all(isnan( ...
                result.rockerRodPointCurrent_m)));
            testCase.verifyTrue(isnan(result.rockerAngle_rad));
        end

        function underconstrainedClosureHasSpecificStatus(testCase)
            [geometry, actuation] = actuationFixture( ...
                "YZ_PLANE", "UPRIGHT", "PUSHROD", "UNDERCONSTRAINED");
            source = fsd.kinematics.solveBump(geometry, 0, "m");
            result = fsd.kinematics.solveActuation(actuation, source);
            testCase.verifyFalse(result.converged);
            testCase.verifyEqual(result.status, "ROCKER_UNDERCONSTRAINED");
            testCase.verifyEqual(result.diagnostics.constraintCase, ...
                "ALL_ANGLES");
            testCase.verifyTrue(isnan(result.rockerAngle_rad));
        end

        function wishboneAttachmentOnPivotAxisIsAllowed(testCase)
            [geometry, ~, definition] = actuationFixture( ...
                "YZ_PLANE", "UCA");
            definition.suspensionAttachment.point = ...
                fsd.model.getPoint(geometry, "FL_UCA_FWD_CHASSIS");
            actuation = fsd.model.createActuationGeometry( ...
                geometry, definition, "m");
            source = fsd.kinematics.solveBump(geometry, 12, "mm");
            result = fsd.kinematics.solveActuation(actuation, source);
            testCase.verifyTrue(result.converged, result.failureReason);
            testCase.verifyEqual(result.suspensionAttachmentCurrent_m, ...
                definition.suspensionAttachment.point, "AbsTol", 1e-13);
            testCase.verifyEqual( ...
                result.diagnostics.attachmentTransform.localLeverArm_m, ...
                0, "AbsTol", 1e-14);
        end

        function failedKinematicsIsNotSolved(testCase)
            [geometry, actuation] = actuationFixture();
            source = fsd.kinematics.solveBump(geometry, 500, "mm");
            result = fsd.kinematics.solveActuation(actuation, source);
            testCase.verifyFalse(result.converged);
            testCase.verifyEqual(result.status, ...
                "KINEMATICS_NOT_CONVERGED");
            testCase.verifyFalse(result.diagnostics.attempted);
            testCase.verifyEqual(result.sourceKinematicStatus, ...
                source.status);
        end

        function rejectsCornerGeometryMismatch(testCase)
            [geometry, actuation] = actuationFixture();
            right = fsd.geometry.reflectDoubleWishboneGeometry(geometry);
            source = fsd.kinematics.solveBump(right, 0, "m");
            testCase.verifyError(@() fsd.kinematics.solveActuation( ...
                actuation, source), ...
                "fsd:kinematics:ActuationGeometryMismatch");
        end

        function validatorRejectsAlteredPayload(testCase)
            [geometry, actuation] = actuationFixture();
            source = fsd.kinematics.solveBump(geometry, 10, "mm");
            result = fsd.kinematics.solveActuation(actuation, source);
            result.damperLength_m = result.damperLength_m + 1e-5;
            testCase.verifyError(@() ...
                fsd.kinematics.validateActuationResult(result, actuation), ...
                "fsd:kinematics:InvalidActuationResult");
        end

        function validatorReconstructsClosedFormBranch(testCase)
            [geometry, actuation] = actuationFixture();
            source = fsd.kinematics.solveBump(geometry, 8, "mm");
            original = fsd.kinematics.solveActuation(actuation, source);
            mutations = cell(6,1);
            mutations{1} = original;
            mutations{1}.diagnostics.candidateAngles_rad(1) = ...
                mutations{1}.diagnostics.candidateAngles_rad(1)+1e-4;
            mutations{2} = original;
            mutations{2}.diagnostics.acosRatio = ...
                mutations{2}.diagnostics.acosRatio+1e-4;
            mutations{3} = original;
            mutations{3}.diagnostics.derivativeMagnitude_m2 = ...
                mutations{3}.diagnostics.derivativeMagnitude_m2+1e-4;
            mutations{4} = original;
            mutations{4}.diagnostics.constraintCase = "TANGENT";
            mutations{5} = original;
            mutations{5}.conditioning = mutations{5}.conditioning+0.1;
            mutations{6} = original;
            mutations{6}.diagnostics.selectedCandidateIndex = ...
                3-original.diagnostics.selectedCandidateIndex;
            for index = 1:numel(mutations)
                testCase.verifyError(@() ...
                    fsd.kinematics.validateActuationResult( ...
                    mutations{index}, actuation), ...
                    "fsd:kinematics:InvalidActuationResult");
            end
        end

        function alternateClosedFormBranchIsValid(testCase)
            [geometry, actuation] = actuationFixture();
            source = fsd.kinematics.solveBump(geometry, 8, "mm");
            first = fsd.kinematics.solveActuation(actuation, source);
            otherIndex = 3-first.diagnostics.selectedCandidateIndex;
            reference = first.diagnostics.candidateAngles_rad(otherIndex);
            other = fsd.kinematics.solveActuation(actuation, source, ...
                struct("ReferenceRockerAngle_rad",reference));
            testCase.verifyNotEqual(other.rockerAngle_rad,first.rockerAngle_rad);
            testCase.verifyTrue(fsd.kinematics.validateActuationResult( ...
                other,actuation));
        end

        function sweepValidatorRejectsAlteredContinuationChain(testCase)
            [geometry, actuation] = actuationFixture();
            bump = fsd.kinematics.solveBumpSweep(geometry,[0;5;10],"mm");
            sweep = fsd.kinematics.solveActuationSweep(actuation,bump);
            sweep.results(2).diagnostics.referenceRockerAngle_rad = 0.2;
            testCase.verifyError(@() ...
                fsd.kinematics.validateActuationSweepResult(sweep,actuation), ...
                "fsd:kinematics:InvalidActuationSweepResult");
        end

        function failedSweepSkipsRemainingClosureSolves(testCase)
            [geometry, actuation] = actuationFixture( ...
                "YZ_PLANE","UPRIGHT","PUSHROD","TANGENT");
            bump = fsd.kinematics.solveBumpSweep(geometry,[0;2;4],"mm");
            sweep = fsd.kinematics.solveActuationSweep(actuation,bump);
            testCase.verifyEqual(sweep.performance.rockerClosureSolveCount,2);
            testCase.verifyEqual(sweep.performance.notAttemptedCount,1);
            testCase.verifyFalse(sweep.results(3).diagnostics.attempted);
            testCase.verifyEqual(sweep.results(3).status,"NOT_ATTEMPTED");
        end

        function steeringCornerValidatorRejectsContradictoryTravel(testCase)
            axle = translationAxleFixture("FRONT");
            steering = fsd.model.createSteeringSystem(axle,1.6,"m");
            [~,actuation] = actuationFixture();
            axleResult = fsd.kinematics.solveSteering( ...
                steering,5,5,"mm");
            corner = axleResult.leftResult;
            testCase.verifyTrue( ...
                fsd.kinematics.validateSteeringCornerResult(corner));
            corner.requestedWheelTravel_m = 0.006;
            corner.achievedWheelTravel_m = 0.005;
            testCase.verifyError(@() ...
                fsd.kinematics.validateSteeringCornerResult(corner), ...
                "fsd:kinematics:InvalidSteeringCornerResult");
            testCase.verifyError(@() fsd.kinematics.solveActuation( ...
                actuation,corner), ...
                "fsd:kinematics:InvalidActuationSource");
        end

        function steeringCornerValidatorRejectsIndependentTampering(testCase)
            axle = translationAxleFixture("FRONT");
            steering = fsd.model.createSteeringSystem(axle,1.6,"m");
            result = fsd.kinematics.solveSteering(steering,5,5,"mm");
            original = result.leftResult;
            mutations = cell(5,1);
            mutations{1} = original;
            mutations{1}.requestedRackTravel_m = 0.006;
            mutations{2} = original;
            mutations{2}.achievedRackTravel_m = 0.006;
            mutations{3} = original;
            mutations{3}.tieRodInboardCurrent_m(2) = ...
                mutations{3}.tieRodInboardCurrent_m(2)+1e-3;
            mutations{4} = original;
            mutations{4}.rackZeroKinematicResult.requestedWheelTravel_m = 0.006;
            mutations{5} = original;
            mutations{5}.cornerId = "FR";
            for index = 1:numel(mutations)
                testCase.verifyError(@() ...
                    fsd.kinematics.validateSteeringCornerResult( ...
                    mutations{index}), ...
                    "fsd:kinematics:InvalidSteeringCornerResult");
            end

            left = axle.leftGeometry;
            right = axle.rightGeometry;
            leftXyz = left.hardpoints.xyz_m;
            rightXyz = right.hardpoints.xyz_m;
            leftXyz(left.hardpoints.ids=="FL_TIE_ROD_INBOARD",1) = ...
                leftXyz(left.hardpoints.ids=="FL_TIE_ROD_INBOARD",1)+0.01;
            rightXyz(right.hardpoints.ids=="FR_TIE_ROD_INBOARD",1) = ...
                rightXyz(right.hardpoints.ids=="FR_TIE_ROD_INBOARD",1)+0.01;
            otherLeft = fsd.model.createDoubleWishboneGeometry("FL", ...
                left.hardpoints.ids,leftXyz,"m",left.wheel.wheelAxis);
            otherRight = fsd.model.createDoubleWishboneGeometry("FR", ...
                right.hardpoints.ids,rightXyz,"m",right.wheel.wheelAxis);
            otherAxle = fsd.model.createAxleGeometry(otherLeft,otherRight);
            otherSteering = fsd.model.createSteeringSystem(otherAxle,1.6,"m");
            changedIdentity = original;
            changedIdentity.steeringSystemIdentity = otherSteering.identity;
            testCase.verifyError(@() ...
                fsd.kinematics.validateSteeringCornerResult(changedIdentity), ...
                "fsd:kinematics:InvalidSteeringCornerResult");
        end

        function failedSteeringCornerIsAValidActuationSource(testCase)
            axle = translationAxleFixture("FRONT");
            steering = fsd.model.createSteeringSystem(axle,1.6,"m");
            [~,actuation] = actuationFixture();
            steeringResult = fsd.kinematics.solveSteering( ...
                steering,1000,0,"mm");
            source = steeringResult.leftResult;
            testCase.verifyFalse(source.converged);
            testCase.verifyTrue( ...
                fsd.kinematics.validateSteeringCornerResult(source));
            result = fsd.kinematics.solveActuation(actuation,source);
            testCase.verifyEqual(result.status,"KINEMATICS_NOT_CONVERGED");
            testCase.verifyFalse(result.diagnostics.attempted);
        end

        function validatorRejectsChangedActuationIdentity(testCase)
            [geometry, actuation, definition] = actuationFixture();
            source = fsd.kinematics.solveBump(geometry, 5, "mm");
            result = fsd.kinematics.solveActuation(actuation, source);

            changedDefinitions = cell(3,1);
            changedDefinitions{1} = definition;
            changedDefinitions{1}.actuationType = "PULLROD";
            changedDefinitions{2} = definition;
            changedDefinitions{2}.rocker.axis.point = [0,0.01,0];
            changedDefinitions{3} = definition;
            changedDefinitions{3}.suspensionAttachment.point = ...
                definition.suspensionAttachment.point+[0,0,1e-4];
            for index = 1:numel(changedDefinitions)
                changed = fsd.model.createActuationGeometry( ...
                    geometry, changedDefinitions{index}, "m");
                testCase.verifyError(@() ...
                    fsd.kinematics.validateActuationResult(result, changed), ...
                    "fsd:kinematics:ActuationIdentityMismatch");
            end
        end

        function sweepValidatorRejectsMixedResults(testCase)
            [geometry, actuation, definition] = actuationFixture();
            bump = fsd.kinematics.solveBumpSweep( ...
                geometry, [0;5;10], "mm");
            sweep = fsd.kinematics.solveActuationSweep(actuation, bump);
            definition.actuationType = "PULLROD";
            other = fsd.model.createActuationGeometry( ...
                geometry, definition, "m");
            otherSweep = fsd.kinematics.solveActuationSweep(other, bump);
            sweep.results(2) = otherSweep.results(2);
            testCase.verifyError(@() ...
                fsd.kinematics.validateActuationSweepResult( ...
                sweep, actuation), ...
                "fsd:kinematics:ActuationIdentityMismatch");
        end

        function consumesSteeringCornerWithoutResolving(testCase)
            axle = translationAxleFixture("FRONT");
            steering = fsd.model.createSteeringSystem(axle, 1.6, "m");
            steeringResult = fsd.kinematics.solveSteering( ...
                steering, 5, [8,8], "mm");
            for body = ["UPRIGHT", "UCA", "LCA"]
                [~, actuation] = actuationFixture("YZ_PLANE", body);
                result = fsd.kinematics.solveActuation( ...
                    actuation, steeringResult.leftResult);
                testCase.verifyTrue(result.converged, result.failureReason);
                testCase.verifyEqual(result.sourceResultKind, ...
                    "SteeringCornerResult");
                testCase.verifyLessThan(abs( ...
                    result.actuationRodLengthResidual_m), 1e-10);
            end
        end

        function mirrorActuationPreservesCompressionAndMrMagnitude(testCase)
            axle = translationAxleFixture("FRONT");
            [~, leftActuation, definition] = actuationFixture();
            rightActuation = fsd.model.createActuationGeometry( ...
                axle.rightGeometry, testCase.reflectDefinition(definition), "m");
            targets = (-15:3:15)';
            leftBump = fsd.kinematics.solveBumpSweep( ...
                axle.leftGeometry, targets, "mm");
            rightBump = fsd.kinematics.solveBumpSweep( ...
                axle.rightGeometry, targets, "mm");
            leftSweep = fsd.kinematics.solveActuationSweep( ...
                leftActuation, leftBump);
            rightSweep = fsd.kinematics.solveActuationSweep( ...
                rightActuation, rightBump);
            leftAnalysis = fsd.analysis.analyzeActuationSweep( ...
                leftActuation, leftSweep);
            rightAnalysis = fsd.analysis.analyzeActuationSweep( ...
                rightActuation, rightSweep);
            testCase.verifyEqual(rightSweep.damperCompression_m, ...
                leftSweep.damperCompression_m, "AbsTol", 2e-12);
            testCase.verifyEqual(abs(rightAnalysis.damperMotionRatio), ...
                abs(leftAnalysis.damperMotionRatio), "AbsTol", 2e-10);
            testCase.verifyEqual(rightSweep.rockerAngle_rad, ...
                -leftSweep.rockerAngle_rad, "AbsTol", 2e-12);
        end

        function asymmetricAxleTravelProducesIndependentStates(testCase)
            axle = translationAxleFixture("FRONT");
            [~, leftActuation, definition] = actuationFixture();
            rightDefinition = testCase.reflectDefinition(definition);
            rightActuation = fsd.model.createActuationGeometry( ...
                axle.rightGeometry, rightDefinition, "m");
            axleResult = fsd.kinematics.solveAxleTravel( ...
                axle, [15,-10], "mm");
            left = fsd.kinematics.solveActuation( ...
                leftActuation, axleResult.leftResult);
            right = fsd.kinematics.solveActuation( ...
                rightActuation, axleResult.rightResult);
            testCase.verifyTrue(left.converged && right.converged);
            testCase.verifyGreaterThan(abs(left.rockerAngle_rad - ...
                right.rockerAngle_rad), 1e-8);
            testCase.verifyGreaterThan(abs(left.damperCompression_m - ...
                right.damperCompression_m), 1e-8);
        end

        function consumesPositiveAndNegativeBodyRollStates(testCase)
            axle = translationAxleFixture("FRONT");
            [~, leftActuation, definition] = actuationFixture();
            rightActuation = fsd.model.createActuationGeometry( ...
                axle.rightGeometry, testCase.reflectDefinition(definition), "m");
            for phi = [-1, 1]
                roll = fsd.kinematics.solveAxleRoll( ...
                    axle, phi, 0, "deg", "m");
                left = fsd.kinematics.solveActuation( ...
                    leftActuation, roll.axleTravelResult.leftResult);
                right = fsd.kinematics.solveActuation( ...
                    rightActuation, roll.axleTravelResult.rightResult);
                testCase.verifyTrue(left.converged && right.converged);
                testCase.verifyLessThan(abs( ...
                    left.actuationRodLengthResidual_m), 1e-10);
                testCase.verifyLessThan(abs( ...
                    right.actuationRodLengthResidual_m), 1e-10);
            end
        end

        function plotShowsAxisRodRockerAndDamper(testCase)
            [geometry, actuation] = actuationFixture("CUSTOM");
            source = fsd.kinematics.solveBump(geometry, 5, "mm");
            result = fsd.kinematics.solveActuation(actuation, source);
            fig = figure("Visible", "off");
            testCase.addTeardown(@() closeIfValid(fig));
            handles = fsd.kinematics.plotActuationResult( ...
                actuation, result, axes(fig));
            testCase.verifyTrue(isgraphics(handles.rockerAxis));
            testCase.verifyTrue(isgraphics(handles.currentRod));
            testCase.verifyTrue(isgraphics(handles.currentDamper));
        end
    end

    methods (Access = private)
        function verifyWishboneAttachment(testCase, body, travel_mm)
            [geometry, actuation] = actuationFixture( ...
                "YZ_PLANE", body);
            source = fsd.kinematics.solveBump(geometry, travel_mm, "mm");
            result = fsd.kinematics.solveActuation(actuation, source);
            testCase.verifyTrue(result.converged, result.failureReason);
            prefix = geometry.cornerId + "_";
            if body == "UCA"
                fwd = fsd.model.getPoint(geometry, ...
                    prefix+"UCA_FWD_CHASSIS");
                aft = fsd.model.getPoint(geometry, ...
                    prefix+"UCA_AFT_CHASSIS");
                bj0 = fsd.model.getPoint(geometry, prefix+"UBJ");
                bj1 = source.state.ubj_m;
            else
                fwd = fsd.model.getPoint(geometry, ...
                    prefix+"LCA_FWD_CHASSIS");
                aft = fsd.model.getPoint(geometry, ...
                    prefix+"LCA_AFT_CHASSIS");
                bj0 = fsd.model.getPoint(geometry, prefix+"LBJ");
                bj1 = source.state.lbj_m;
            end
            u = (aft-fwd)/norm(aft-fwd);
            r0 = bj0-fwd-dot(bj0-fwd,u)*u;
            r1 = bj1-fwd-dot(bj1-fwd,u)*u;
            beta = atan2(dot(u,cross(r0,r1)),dot(r0,r1));
            expected = fwd + (testCase.rodrigues(u,beta) * ...
                (actuation.suspensionAttachment.pointStatic_m-fwd)')';
            actual = result.suspensionAttachmentCurrent_m;
            testCase.verifyEqual(actual, expected, "AbsTol", 2e-10);
            testCase.verifyEqual(dot(actual-fwd,u), ...
                dot(actuation.suspensionAttachment.pointStatic_m-fwd,u), ...
                "AbsTol", 2e-10);
            testCase.verifyEqual(norm(cross(actual-fwd,u)), ...
                norm(cross(actuation.suspensionAttachment.pointStatic_m-fwd,u)), ...
                "AbsTol", 2e-10);
            testCase.verifyEqual(norm(actual-bj1), ...
                norm(actuation.suspensionAttachment.pointStatic_m-bj0), ...
                "AbsTol", 2e-10);
            expectedFromAft = aft + (testCase.rodrigues(u,beta) * ...
                (actuation.suspensionAttachment.pointStatic_m-aft)')';
            testCase.verifyEqual(expectedFromAft, expected, "AbsTol", 2e-14);
            recovered = fwd + (testCase.rodrigues(u,-beta) * ...
                (actual-fwd)')';
            testCase.verifyEqual(recovered, ...
                actuation.suspensionAttachment.pointStatic_m, ...
                "AbsTol", 2e-10);
        end

        function verifyRockerRigidity(testCase, actuation, result)
            axis = actuation.rocker.axis;
            staticPoints = [actuation.rocker.actuationRodPoint.pointStatic_m; ...
                actuation.rocker.damperPoint.pointStatic_m];
            currentPoints = [result.rockerRodPointCurrent_m; ...
                result.rockerDamperPointCurrent_m];
            for index = 1:2
                testCase.verifyEqual(norm(cross( ...
                    staticPoints(index,:)-axis.point_m, ...
                    axis.direction_unit)), norm(cross( ...
                    currentPoints(index,:)-axis.point_m, ...
                    axis.direction_unit)), "AbsTol", 1e-13);
                testCase.verifyEqual(dot( ...
                    staticPoints(index,:)-axis.point_m, ...
                    axis.direction_unit), dot( ...
                    currentPoints(index,:)-axis.point_m, ...
                    axis.direction_unit), "AbsTol", 1e-13);
            end
            testCase.verifyEqual(norm(diff(staticPoints)), ...
                norm(diff(currentPoints)), "AbsTol", 1e-13);
        end
    end

    methods (Static, Access = private)
        function R = rodrigues(u, angle)
            ux = [0,-u(3),u(2); u(3),0,-u(1); -u(2),u(1),0];
            R = eye(3)*cos(angle) + (1-cos(angle))*(u'*u) + sin(angle)*ux;
        end

        function definition = reflectDefinition(definition)
            definition.suspensionAttachment.point(2) = ...
                -definition.suspensionAttachment.point(2);
            definition.rocker.axis.point(2) = ...
                -definition.rocker.axis.point(2);
            definition.rocker.actuationRodPoint(2) = ...
                -definition.rocker.actuationRodPoint(2);
            definition.rocker.damperPoint(2) = ...
                -definition.rocker.damperPoint(2);
            definition.damper.chassisPoint(2) = ...
                -definition.damper.chassisPoint(2);
        end
    end
end

function closeIfValid(figureHandle)
if isgraphics(figureHandle, "figure")
    close(figureHandle);
end
end
