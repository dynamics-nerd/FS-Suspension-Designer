function valid=validateAntiRollBarState(state,bar)
%VALIDATEANTIROLLBARSTATE Algebraic reconstruction from canonical source poses.
assert(isstruct(state)&&isscalar(state)&&all(isfield(state,{'sources','referenceRotations_rad','expectedBranchSigns'}))&& ...
    isequaln(state,fsd.kinematics.solveAntiRollBar(bar,state.sources,state.referenceRotations_rad,state.expectedBranchSigns)), ...
    'fsd:kinematics:InvalidAntiRollBar','ARB state differs from its geometry/parents/branch.');
valid=true;
end
