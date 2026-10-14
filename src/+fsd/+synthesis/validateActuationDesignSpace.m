function valid = validateActuationDesignSpace(space)
%VALIDATEACTUATIONDESIGNSPACE Canonical reconstruction of bindings and sources.
try
    expected=actuationSpaceCore(space.seed,space.seedActuation,space.seedMechanical,space.specification,space.plan);
    requireSynthesis(isequaln(space,expected),'Actuation design space mismatch.');
catch cause
    exception=MException('fsd:synthesis:InvalidActuationDesignSpace','Actuation design space is inconsistent.');
    throwAsCaller(addCause(exception,cause));
end
valid=true;
end
