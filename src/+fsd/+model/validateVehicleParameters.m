function valid = validateVehicleParameters(vehicle)
%VALIDATEVEHICLEPARAMETERS Reconstruct all derived fields and canonical identity.
vehicleRequire(isstruct(vehicle) && isscalar(vehicle) && ...
    all(isfield(vehicle,["definitionSI","metadata"])) && ...
    isstruct(vehicle.metadata) && isscalar(vehicle.metadata),"Invalid vehicle payload.");
expected = vehicleParametersCore(vehicle.definitionSI);
vehicleRequire(isequaln(rmfield(vehicle,"metadata"),rmfield(expected,"metadata")), ...
    "Inconsistent vehicle payload or identity.");
valid = true;
end
