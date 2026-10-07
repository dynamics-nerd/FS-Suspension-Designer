function result = solveAxleTravelCore(axle, requested_m, settings)
%SOLVEAXLETRAVELCORE Solve one prevalidated bilateral travel target.

timer = tic;
leftResults = solveBumpPath( ...
    axle.leftGeometry, requested_m(1), settings);
rightResults = solveBumpPath( ...
    axle.rightGeometry, requested_m(2), settings);
result = composeAxleTravelResult(axle, requested_m, ...
    leftResults(1), rightResults(1), toc(timer));
end
