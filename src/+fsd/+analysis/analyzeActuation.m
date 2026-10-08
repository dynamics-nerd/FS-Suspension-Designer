function analysis = analyzeActuation(actuation, result)
%ANALYZEACTUATION Validate and expose one geometric actuation state.

fsd.model.validateActuationGeometry(actuation);
fsd.kinematics.validateActuationResult(result, actuation);
analysis = analyzeActuationCore(actuation, result);
fsd.analysis.validateActuationAnalysis(analysis, actuation, result);
end
