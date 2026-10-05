classdef TestStaticDoubleWishboneGeometry < matlab.unittest.TestCase
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
        function constructsValidGeometryInMetres(testCase)
            [corner, ids, xyz_m, wheelAxis, provenance] = ...
                testCase.validInputs("m");
            geometry = fsd.model.createDoubleWishboneGeometry( ...
                corner, ids, xyz_m, "m", wheelAxis, provenance);

            testCase.verifyTrue( ...
                fsd.model.validateDoubleWishboneGeometry(geometry));
            testCase.verifyEqual(geometry.hardpoints.xyz_m, xyz_m);
            testCase.verifyEqual(geometry.metadata.lengthUnit, "m");
        end

        function constructsValidGeometryInMillimetres(testCase)
            [corner, ids, xyz_mm, wheelAxis, provenance] = ...
                testCase.validInputs("mm");
            geometry = fsd.model.createDoubleWishboneGeometry( ...
                corner, ids, xyz_mm, "mm", wheelAxis, provenance);

            testCase.verifyEqual(geometry.hardpoints.xyz_m, xyz_mm / 1000, ...
                "AbsTol", 1e-15);
            testCase.verifyEqual( ...
                fsd.model.getPoint(geometry, "FL_WHEEL_CENTER"), ...
                [0, -0.570, 0.250], "AbsTol", 1e-15);
        end

        function normalizesWheelAxis(testCase)
            [corner, ids, xyz, ~, provenance] = testCase.validInputs("m");
            geometry = fsd.model.createDoubleWishboneGeometry( ...
                corner, ids, xyz, "m", [0, -4, 0], provenance);
            testCase.verifyEqual(geometry.wheel.wheelAxis, [0, -1, 0], ...
                "AbsTol", 1e-15);
        end

        function preservesCoordinateLevelProvenance(testCase)
            [corner, ids, xyz, wheelAxis, provenance] = ...
                testCase.validInputs("m");
            provenance.sourceKind(1,:) = ["KNOWN", "ASSUMED", "DERIVED"];
            provenance.sourceNote(1,:) = ["CAD", "Packaging", "Optimization"];
            geometry = fsd.model.createDoubleWishboneGeometry( ...
                corner, ids, xyz, "m", wheelAxis, provenance);

            testCase.verifyEqual(geometry.hardpoints.sourceKind(1,:), ...
                ["KNOWN", "ASSUMED", "DERIVED"]);
            testCase.verifyEqual(geometry.hardpoints.sourceNote(1,:), ...
                ["CAD", "Packaging", "Optimization"]);
        end

        function rejectsIncorrectXyzShape(testCase)
            [corner, ids, ~, wheelAxis, provenance] = testCase.validInputs("m");
            testCase.verifyError(@() fsd.model.createDoubleWishboneGeometry( ...
                corner, ids, zeros(3, 8), "m", wheelAxis, provenance), ...
                "fsd:model:InvalidXyzShape");
        end

        function rejectsDuplicateId(testCase)
            [corner, ids, xyz, wheelAxis, provenance] = testCase.validInputs("m");
            ids(2) = ids(1);
            testCase.verifyError(@() fsd.model.createDoubleWishboneGeometry( ...
                corner, ids, xyz, "m", wheelAxis, provenance), ...
                "fsd:model:DuplicateId");
        end

        function rejectsMissingRequiredId(testCase)
            [corner, ids, xyz, wheelAxis, provenance] = testCase.validInputs("m");
            ids(end) = [];
            xyz(end,:) = [];
            provenance.sourceKind(end,:) = [];
            provenance.sourceNote(end,:) = [];
            testCase.verifyError(@() fsd.model.createDoubleWishboneGeometry( ...
                corner, ids, xyz, "m", wheelAxis, provenance), ...
                "fsd:model:MissingRequiredId");
        end

        function rejectsNaN(testCase)
            [corner, ids, xyz, wheelAxis, provenance] = testCase.validInputs("m");
            xyz(1,1) = NaN;
            testCase.verifyError(@() fsd.model.createDoubleWishboneGeometry( ...
                corner, ids, xyz, "m", wheelAxis, provenance), ...
                "fsd:model:NonFiniteCoordinate");
        end

        function rejectsInf(testCase)
            [corner, ids, xyz, wheelAxis, provenance] = testCase.validInputs("m");
            xyz(1,1) = Inf;
            testCase.verifyError(@() fsd.model.createDoubleWishboneGeometry( ...
                corner, ids, xyz, "m", wheelAxis, provenance), ...
                "fsd:model:NonFiniteCoordinate");
        end

        function rejectsInvalidCorner(testCase)
            [~, ids, xyz, wheelAxis, provenance] = testCase.validInputs("m");
            testCase.verifyError(@() fsd.model.createDoubleWishboneGeometry( ...
                "XX", ids, xyz, "m", wheelAxis, provenance), ...
                "fsd:model:InvalidCorner");
        end

        function rejectsCornerPrefixMismatch(testCase)
            [~, ids, xyz, wheelAxis, provenance] = testCase.validInputs("m");
            testCase.verifyError(@() fsd.model.createDoubleWishboneGeometry( ...
                "FR", ids, xyz, "m", wheelAxis, provenance), ...
                "fsd:model:CornerPrefixMismatch");
        end

        function rejectsCoincidentBallJoints(testCase)
            testCase.verifyCoincidentPairRejected( ...
                "FL_UBJ", "FL_LBJ", "fsd:model:CoincidentUBJLBJ");
        end

        function rejectsCoincidentUcaPivots(testCase)
            testCase.verifyCoincidentPairRejected( ...
                "FL_UCA_FWD_CHASSIS", "FL_UCA_AFT_CHASSIS", ...
                "fsd:model:CoincidentUcaPivots");
        end

        function rejectsCoincidentLcaPivots(testCase)
            testCase.verifyCoincidentPairRejected( ...
                "FL_LCA_FWD_CHASSIS", "FL_LCA_AFT_CHASSIS", ...
                "fsd:model:CoincidentLcaPivots");
        end

        function rejectsCoincidentWheelReferences(testCase)
            testCase.verifyCoincidentPairRejected( ...
                "FL_WHEEL_CENTER", "FL_CONTACT_PATCH", ...
                "fsd:model:CoincidentWheelReferences");
        end

        function rejectsZeroWheelAxis(testCase)
            [corner, ids, xyz, ~, provenance] = testCase.validInputs("m");
            testCase.verifyError(@() fsd.model.createDoubleWishboneGeometry( ...
                corner, ids, xyz, "m", [0, 0, 0], provenance), ...
                "fsd:model:ZeroWheelAxis");
        end

        function rejectsInvalidWheelAxis(testCase)
            [corner, ids, xyz, ~, provenance] = testCase.validInputs("m");
            testCase.verifyError(@() fsd.model.createDoubleWishboneGeometry( ...
                corner, ids, xyz, "m", [0; -1; 0], provenance), ...
                "fsd:model:InvalidWheelAxis");
            testCase.verifyError(@() fsd.model.createDoubleWishboneGeometry( ...
                corner, ids, xyz, "m", [0, NaN, 0], provenance), ...
                "fsd:model:InvalidWheelAxis");
        end

        function rejectsInwardWheelAxis(testCase)
            [corner, ids, xyz, ~, provenance] = testCase.validInputs("m");
            testCase.verifyError(@() fsd.model.createDoubleWishboneGeometry( ...
                corner, ids, xyz, "m", [0, 1, 0], provenance), ...
                "fsd:model:WheelAxisNotOutward");
        end

        function getsPointById(testCase)
            geometry = testCase.validGeometry();
            testCase.verifyEqual( ...
                fsd.model.getPoint(geometry, "FL_UBJ"), ...
                [0.020, -0.520, 0.340], "AbsTol", 1e-15);
        end

        function rejectsUnknownPointQuery(testCase)
            geometry = testCase.validGeometry();
            testCase.verifyError(@() fsd.model.getPoint( ...
                geometry, "FL_UNKNOWN"), "fsd:model:PointNotFound");
        end

        function computesKnownDistance(testCase)
            geometry = testCase.validGeometry();
            actual = fsd.geometry.distanceBetweenPoints(geometry, ...
                "FL_UCA_FWD_CHASSIS", "FL_UCA_AFT_CHASSIS");
            testCase.verifyEqual(actual, 0.280, "AbsTol", 1e-15);
        end

        function computesKnownUnitVector(testCase)
            geometry = testCase.validGeometry();
            actual = fsd.geometry.unitVectorBetweenPoints(geometry, ...
                "FL_UCA_FWD_CHASSIS", "FL_UCA_AFT_CHASSIS");
            testCase.verifyEqual(actual, [1, 0, 0], "AbsTol", 1e-15);
        end

        function computesStaticMetrics(testCase)
            geometry = testCase.validGeometry();
            metrics = fsd.geometry.staticMetrics(geometry);
            testCase.verifyEqual(metrics.ucaInboardAxisLength_m, 0.280, ...
                "AbsTol", 1e-15);
            testCase.verifyEqual(metrics.lcaInboardAxisLength_m, ...
                sqrt(0.350^2 + 0.010^2), "AbsTol", 1e-15);
            testCase.verifyEqual(metrics.wheelCenterContactPatchDistance_m, ...
                sqrt(0.030^2 + 0.250^2), "AbsTol", 1e-15);
        end

        function reflectsLeftToRight(testCase)
            left = testCase.validGeometry();
            right = fsd.geometry.reflectDoubleWishboneGeometry(left);

            testCase.verifyEqual(right.cornerId, "FR");
            testCase.verifyEqual(right.hardpoints.xyz_m(:, [1,3]), ...
                left.hardpoints.xyz_m(:, [1,3]), "AbsTol", 1e-15);
            testCase.verifyEqual(right.hardpoints.xyz_m(:,2), ...
                -left.hardpoints.xyz_m(:,2), "AbsTol", 1e-15);
            testCase.verifyTrue(all(startsWith(right.hardpoints.ids, "FR_")));
            testCase.verifyEqual(right.hardpoints.sourceKind, ...
                left.hardpoints.sourceKind);
            testCase.verifyEqual(right.hardpoints.sourceNote, ...
                left.hardpoints.sourceNote);
        end

        function reflectsWheelAxis(testCase)
            right = fsd.geometry.reflectDoubleWishboneGeometry( ...
                testCase.validGeometry());
            testCase.verifyEqual(right.wheel.wheelAxis, [0, 1, 0], ...
                "AbsTol", 1e-15);
        end

        function doubleReflectionReturnsOriginal(testCase)
            original = testCase.validGeometry();
            recovered = fsd.geometry.reflectDoubleWishboneGeometry( ...
                fsd.geometry.reflectDoubleWishboneGeometry(original));
            testCase.verifyEqual(recovered, original);
        end

        function savesAndLoadsMatGeometry(testCase)
            geometry = testCase.validGeometry();
            filePath = string(tempname) + ".mat";
            testCase.addTeardown(@() deleteIfPresent(filePath));
            fsd.model.saveGeometryMat(filePath, geometry);
            loaded = fsd.model.loadGeometryMat(filePath);
            testCase.verifyEqual(loaded, geometry);
        end

        function plotsIntoSuppliedAxes(testCase)
            geometry = testCase.validGeometry();
            figureHandle = figure("Visible", "off");
            testCase.addTeardown(@() closeIfValid(figureHandle));
            axesHandle = axes(figureHandle);
            handles = fsd.geometry.plotDoubleWishboneGeometry( ...
                geometry, axesHandle);

            testCase.verifyTrue(isgraphics(handles.axes, "axes"));
            testCase.verifyTrue(all(isgraphics(handles.uca)));
            testCase.verifyTrue(all(isgraphics(handles.lca)));
            testCase.verifyTrue(isgraphics(handles.wheelAxis));
            testCase.verifyEqual(handles.axes.DataAspectRatio, [1, 1, 1]);
        end
    end

    methods (Access = private)
        function verifyCoincidentPairRejected(testCase, idA, idB, errorId)
            [corner, ids, xyz, wheelAxis, provenance] = ...
                testCase.validInputs("m");
            xyz(ids == idB,:) = xyz(ids == idA,:);
            testCase.verifyError(@() fsd.model.createDoubleWishboneGeometry( ...
                corner, ids, xyz, "m", wheelAxis, provenance), errorId);
        end

        function geometry = validGeometry(testCase)
            [corner, ids, xyz, wheelAxis, provenance] = ...
                testCase.validInputs("m");
            geometry = fsd.model.createDoubleWishboneGeometry( ...
                corner, ids, xyz, "m", wheelAxis, provenance);
        end
    end

    methods (Static, Access = private)
        function [corner, ids, xyz, wheelAxis, provenance] = validInputs(unit)
            corner = "FL";
            roles = fsd.model.requiredHardpointRoles();
            ids = corner + "_" + roles;
            xyz_m = [ ...
                -0.180, -0.250, 0.330; ...
                 0.100, -0.250, 0.330; ...
                 0.020, -0.520, 0.340; ...
                -0.220, -0.260, 0.100; ...
                 0.130, -0.260, 0.110; ...
                -0.010, -0.530, 0.120; ...
                 0.000, -0.570, 0.250; ...
                 0.000, -0.600, 0.000];
            if unit == "mm"
                xyz = xyz_m * 1000;
            else
                xyz = xyz_m;
            end
            wheelAxis = [0, -1, 0];
            provenance = struct( ...
                "sourceKind", repmat("ASSUMED", 8, 3), ...
                "sourceNote", repmat("Analytic test fixture", 8, 3));
        end
    end
end

function deleteIfPresent(filePath)
if isfile(filePath)
    delete(filePath);
end
end

function closeIfValid(figureHandle)
if isgraphics(figureHandle, "figure")
    close(figureHandle);
end
end
