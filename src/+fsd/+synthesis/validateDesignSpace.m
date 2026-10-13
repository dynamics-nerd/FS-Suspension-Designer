function valid = validateDesignSpace(space)
%VALIDATEDESIGNSPACE Reconstruct bindings, bounds, seed and supported analyses.
try
    expected = spaceCore(space.seed,space.specification,space.plan);
    assert(isequaln(space,expected));
catch cause
    exception = MException('fsd:synthesis:InvalidDesignSpace','Design space is inconsistent.');
    throwAsCaller(addCause(exception,cause));
end
valid = true;
end
