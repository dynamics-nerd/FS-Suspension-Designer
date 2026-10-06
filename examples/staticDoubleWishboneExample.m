function result = staticDoubleWishboneExample(showPlots)
%STATICDOUBLEWISHBONEEXAMPLE Reproducible static v0.2 geometry.
%   The values are fictitious demonstration data. They are not design
%   recommendations and must not be used to manufacture a suspension.

if nargin < 1
    showPlots = true;
end

corner = "FL";
roles = fsd.model.requiredHardpointRoles();
ids = corner + "_" + roles;

% Fictitious demonstration coordinates, deliberately entered in mm.
xyz_mm = [ ...
    -180, -250, 330; ... % UCA forward chassis pivot
     100, -250, 330; ... % UCA aft chassis pivot
      20, -520, 340; ... % UBJ
    -220, -260, 100; ... % LCA forward chassis pivot
     130, -260, 110; ... % LCA aft chassis pivot
     -10, -530, 120; ... % LBJ
      30, -280, 220; ... % Tie rod inboard
      40, -500, 230; ... % Tie rod outboard
       0, -570, 250; ... % Wheel center
       0, -600,   0];    % Contact patch

provenance = struct( ...
    "sourceKind", repmat("ASSUMED", 10, 3), ...
    "sourceNote", repmat("Fictitious demonstration value", 10, 3));

geometryFL = fsd.model.createDoubleWishboneGeometry( ...
    corner, ids, xyz_mm, "mm", [0, -1, 0], provenance);
fsd.model.validateDoubleWishboneGeometry(geometryFL);

ubj_m = fsd.model.getPoint(geometryFL, "FL_UBJ");
wheelCenter_m = fsd.model.getPoint(geometryFL, "FL_WHEEL_CENTER");
metricsFL = fsd.geometry.staticMetrics(geometryFL);

geometryFR = fsd.geometry.reflectDoubleWishboneGeometry(geometryFL);
fsd.model.validateDoubleWishboneGeometry(geometryFR);
geometryFLRecovered = fsd.geometry.reflectDoubleWishboneGeometry(geometryFR);

tolerances = fsd.model.numericTolerances();
doubleReflectionError_m = max(abs( ...
    geometryFLRecovered.hardpoints.xyz_m - geometryFL.hardpoints.xyz_m), ...
    [], "all");
assert(doubleReflectionError_m <= tolerances.AbsTol_m, ...
    "fsd:example:DoubleReflectionFailed", ...
    "Double reflection did not recover the input geometry.");
assert(max(abs(geometryFL.hardpoints.xyz_m - xyz_mm / 1000), [], "all") ...
    <= tolerances.AbsTol_m, "fsd:example:UnitConversionFailed", ...
    "Millimetre input was not stored in metres.");

plotHandles = struct();
if showPlots
    figureHandle = figure("Name", "Static geometry demonstration");
    layout = tiledlayout(figureHandle, 1, 2);
    axesFL = nexttile(layout);
    plotHandles.FL = fsd.geometry.plotDoubleWishboneGeometry(geometryFL, axesFL);
    axesFR = nexttile(layout);
    plotHandles.FR = fsd.geometry.plotDoubleWishboneGeometry(geometryFR, axesFR);
end

result = struct( ...
    "geometryFL", geometryFL, ...
    "geometryFR", geometryFR, ...
    "ubj_m", ubj_m, ...
    "wheelCenter_m", wheelCenter_m, ...
    "metricsFL", metricsFL, ...
    "doubleReflectionError_m", doubleReflectionError_m, ...
    "plotHandles", plotHandles);
end
