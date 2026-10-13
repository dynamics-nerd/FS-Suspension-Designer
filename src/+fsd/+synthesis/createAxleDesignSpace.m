function space = createAxleDesignSpace(leftSeed,rightSeed,specification,plan,symmetryLinks)
%CREATEAXLEDESIGNSPACE Two explicit seeds, joint specification and native plans.
% PLAN.leftBump/rightBump follow v0.12; optional PLAN.roll has angles_rad,
% axleHeave_m and solverOptions. LINKS is an N-by-2 string array of parameter IDs.
if nargin<5, symmetryLinks=strings(0,2); end
space=axleSpaceCore(leftSeed,rightSeed,specification,plan,symmetryLinks);
end
