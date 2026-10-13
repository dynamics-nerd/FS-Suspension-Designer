function valid = validateSteeringDesignSpace(space)
%VALIDATESTEERINGDESIGNSPACE Reconstruct joint bindings and intersected bounds.
try
    expected=steeringSpaceCore(space.seedAxle.leftGeometry,space.seedAxle.rightGeometry,space.seedSteering, ...
        space.specification,space.plan,space.symmetryLinks);
    requireSynthesis(isequaln(space,expected),'Steering space mismatch.');
catch cause
    exception=MException('fsd:synthesis:InvalidSteeringDesignSpace','Steering design space is inconsistent.');
    throwAsCaller(addCause(exception,cause));
end
valid=true;
end
