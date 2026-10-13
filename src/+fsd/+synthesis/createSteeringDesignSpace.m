function space = createSteeringDesignSpace(leftSeed,rightSeed,steeringSeed,specification,plan,symmetryLinks)
%CREATESTEERINGDESIGNSPACE One native FRONT mechanism, bounded bindings and plans.
if nargin<6, symmetryLinks=strings(0,2); end
space=steeringSpaceCore(leftSeed,rightSeed,steeringSeed,specification,plan,symmetryLinks);
end
