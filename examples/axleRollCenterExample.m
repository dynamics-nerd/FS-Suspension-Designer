function output = axleRollCenterExample(showPlots)
%AXLEROLLCENTEREXAMPLE Demonstrate v0.4 axle geometry and RC migration.
%   All coordinates are fictitious demonstration data, not Formula Student
%   targets or manufacturing recommendations.

if nargin < 1
    showPlots = true;
end

leftGeometry = demonstrationCorner();
rightGeometry = fsd.geometry.reflectDoubleWishboneGeometry(leftGeometry);
axle = fsd.model.createAxleGeometry(leftGeometry, rightGeometry);
staticAnalysis = fsd.analysis.analyzeAxleState(axle);
heaveResult = fsd.kinematics.solveAxleHeave(axle, 15, "mm");
heaveAnalysis = fsd.analysis.analyzeAxleState(axle, heaveResult);
travel_mm = (-30:5:30)';
heaveSweep = fsd.kinematics.solveAxleHeaveSweep( ...
    axle, travel_mm, "mm");
migration = fsd.analysis.analyzeAxleHeaveSweep(axle, heaveSweep);

if ~heaveSweep.allConverged
    error("fsd:example:AxleKinematicsDidNotConverge", ...
        "The fictitious v0.4 axle sweep did not converge on both sides.");
end

plotHandles = struct();
if showPlots
    frontViewFigure = figure("Name", "v0.4 axle front view");
    plotHandles.frontView = fsd.analysis.plotAxleFrontView( ...
        staticAnalysis, axes(frontViewFigure));
    migrationFigure = figure("Name", "v0.4 roll-center migration");
    plotHandles.migration = fsd.analysis.plotRollCenterMigration( ...
        migration, migrationFigure);
end

output = struct( ...
    "axle", axle, ...
    "staticAnalysis", staticAnalysis, ...
    "heaveResult", heaveResult, ...
    "heaveAnalysis", heaveAnalysis, ...
    "heaveSweep", heaveSweep, ...
    "migration", migration, ...
    "timing", struct( ...
        "solver_s", heaveSweep.elapsedTime_s, ...
        "analysis_s", migration.analysisElapsedTime_s), ...
    "plotHandles", plotHandles);
end

function geometry = demonstrationCorner()
cornerId = "FL";
ids = cornerId + "_" + fsd.model.requiredHardpointRoles();
xyz_mm = [ ...
    -100, -400, 350; ... % UCA forward chassis
     100, -400, 350; ... % UCA aft chassis
       0, -600, 5/12 * 1000; ... % UBJ
    -100, -400, 150; ... % LCA forward chassis
     100, -400, 150; ... % LCA aft chassis
       0, -600, 1/12 * 1000; ... % LBJ
      50, -400, 250; ... % tie rod inboard
      50, -570, 230; ... % tie rod outboard
       0, -650, 250; ... % Wheel Center
       0, -650,   0];    % static ideal contact datum
provenance = struct( ...
    "sourceKind", repmat("ASSUMED", 10, 3), ...
    "sourceNote", repmat("Fictitious v0.4 demonstration", 10, 3));
geometry = fsd.model.createDoubleWishboneGeometry( ...
    cornerId, ids, xyz_mm, "mm", [0, -1, 0], provenance);
end
