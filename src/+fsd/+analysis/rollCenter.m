function analysis = rollCenter(axle, axleResult)
%ROLLCENTER Public convenience wrapper for axle roll-center analysis.

if nargin < 2
    analysis = fsd.analysis.analyzeAxleState(axle);
else
    analysis = fsd.analysis.analyzeAxleState(axle, axleResult);
end
end
