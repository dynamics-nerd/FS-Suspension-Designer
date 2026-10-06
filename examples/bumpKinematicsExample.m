function output = bumpKinematicsExample(showPlots)
%BUMPKINEMATICSEXAMPLE Demonstrate v0.2 bump kinematics and camber.
%   Hardpoints are fictitious demonstration data, not Formula Student
%   targets or manufacturing recommendations.

if nargin < 1
    showPlots = true;
end

staticExample = staticDoubleWishboneExample(false);
geometry = staticExample.geometryFL;

staticResult = fsd.kinematics.solveBump(geometry, 0, "mm");
bumpResult = fsd.kinematics.solveBump(geometry, 20, "mm");
reboundResult = fsd.kinematics.solveBump(geometry, -20, "mm");
sweep = fsd.kinematics.solveBumpSweep(geometry, (-30:5:30)', "mm");

if ~(staticResult.converged && bumpResult.converged && ...
        reboundResult.converged && sweep.allConverged)
    error("fsd:example:KinematicsDidNotConverge", ...
        "The v0.2 demonstration geometry did not converge.");
end

plotHandles = struct();
if showPlots
    figureHandle = figure("Name", "v0.2 bump kinematics demonstration");
    layout = tiledlayout(figureHandle, 1, 2);
    axesGeometry = nexttile(layout);
    plotHandles.geometry = fsd.kinematics.plotBumpResult( ...
        geometry, bumpResult, axesGeometry);
    axesCamber = nexttile(layout);
    plotHandles.camber = plot(axesCamber, ...
        sweep.achievedWheelTravel_m * 1000, ...
        sweep.camber_rad * 180 / pi, "o-", "LineWidth", 1.5);
    grid(axesCamber, "on");
    xlabel(axesCamber, "Wheel travel [mm]");
    ylabel(axesCamber, "Camber [deg]");
    title(axesCamber, "Camber vs wheel travel");
end

output = struct( ...
    "geometry", geometry, ...
    "staticResult", staticResult, ...
    "bumpResult", bumpResult, ...
    "reboundResult", reboundResult, ...
    "sweep", sweep, ...
    "plotHandles", plotHandles);
end
