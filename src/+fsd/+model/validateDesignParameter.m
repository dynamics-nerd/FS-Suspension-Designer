function valid = validateDesignParameter(parameter)
%VALIDATEDESIGNPARAMETER Reconstruct the canonical role/provenance/availability contract.
designValidateRecord(parameter,"DesignParameter",@designParameterCore);
valid = true;
end
