function valid = validateAxleDesignSpace(space)
%VALIDATEAXLEDESIGNSPACE Reconstruct joint bindings and intersected bounds.
try
    expected=axleSpaceCore(space.seedAxle.leftGeometry,space.seedAxle.rightGeometry, ...
        space.specification,space.plan,space.symmetryLinks);
    requireSynthesis(isequaln(space,expected),'Axle space mismatch.');
catch cause
    exception=MException('fsd:synthesis:InvalidAxleDesignSpace','Axle design space is inconsistent.');
    throwAsCaller(addCause(exception,cause));
end
valid=true;
end
