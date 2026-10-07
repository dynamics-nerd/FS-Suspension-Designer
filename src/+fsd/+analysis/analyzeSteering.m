function analysis = analyzeSteering(steering, result)
%ANALYZESTEERING Validate and analyze one bilateral steering state.

fsd.kinematics.validateSteeringResult(result, steering);
analysis = analyzeSteeringCore(steering, result);
end
