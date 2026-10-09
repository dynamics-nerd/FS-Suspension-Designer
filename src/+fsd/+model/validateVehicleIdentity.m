function valid = validateVehicleIdentity(identity)
%VALIDATEVEHICLEIDENTITY Reconstruct mass and CG, without suspension geometry.
vehicleRequire(isstruct(identity) && isscalar(identity) && isfield(identity,"definitionSI"), ...
    "Invalid vehicle identity.");
expected = vehicleParametersCore(identity.definitionSI);
vehicleRequire(isequaln(identity,expected.identity),"Inconsistent vehicle identity.");
valid = true;
end
