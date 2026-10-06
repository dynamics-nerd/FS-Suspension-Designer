function output = singleCornerAnalysisExample(showPlots)
%SINGLECORNERANALYSISEXAMPLE Demonstrate v0.3 derived kinematic metrics.
%   Hardpoints are fictitious demonstration data, not Formula Student
%   targets or manufacturing recommendations.

if nargin < 1
    showPlots = true;
end

staticExample = staticDoubleWishboneExample(false);
geometry = staticExample.geometryFL;
travel_mm = (-30:5:30)';
sweep = fsd.kinematics.solveBumpSweep(geometry, travel_mm, "mm");
analysis = fsd.analysis.analyzeBumpSweep(geometry, sweep);

if ~analysis.allConverged
    error("fsd:example:KinematicsDidNotConverge", ...
        "The v0.3 demonstration sweep did not converge.");
end

plotHandles = struct();
if showPlots
    comparisonFigure = figure( ...
        "Name", "v0.3 geometry and displaced state");
    comparisonAxes = axes(comparisonFigure);
    bumpIndex = find(travel_mm == 20, 1);
    plotHandles.geometry = fsd.kinematics.plotBumpResult( ...
        geometry, sweep.results(bumpIndex), comparisonAxes);

    analysisFigure = figure("Name", "v0.3 analysis curves");
    plotHandles.analysis = fsd.analysis.plotBumpSweepAnalysis( ...
        analysis, analysisFigure);
end

output = struct( ...
    "geometry", geometry, ...
    "sweep", sweep, ...
    "analysis", analysis, ...
    "timing", struct( ...
        "solver_s", sweep.elapsedTime_s, ...
        "analysis_s", analysis.analysisElapsedTime_s), ...
    "plotHandles", plotHandles);
end
