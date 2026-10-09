function vehicle = createVehicleParameters(definition, units)
%CREATEVEHICLEPARAMETERS Standalone vehicle contract, explicit SI/length boundary.
% See docs/vehicle-static-equilibrium.md; no implicit gravity or unknown zero.
vehicleRequire(isstruct(units) && isscalar(units) && ...
    all(isfield(units,["length","mass","gravity"])),"Incomplete vehicle units.");
vehicleRequire(vehicleText(units.mass) == "kg" && vehicleText(units.gravity) == "m/s^2", ...
    "Mass must be kg and gravity m/s^2.");
factor = fsd.model.convertLengthToMetres(1,units.length);
vehicleRequire(isstruct(definition) && isscalar(definition),"Invalid definition.");
d = definition; metadata = struct;
if isfield(d,"metadata"), metadata = d.metadata; d = rmfield(d,"metadata"); end
vehicleRequire(isstruct(metadata) && isscalar(metadata),"Invalid metadata.");
for name = ["wheelbase","frontTrack","rearTrack","cg","contactPoints"]
    if isfield(d,name), d.(name) = convertKnown(d.(name),factor); end
end
if isfield(d,"components")
    for i = 1:numel(d.components)
        if isfield(d.components,"cg"), d.components(i).cg = convertKnown(d.components(i).cg,factor); end
    end
end
vehicle = vehicleParametersCore(d); vehicle.metadata = metadata;
end

function value = convertKnown(value,factor)
vehicleRequire(isnumeric(value) && isreal(value),"Invalid length value.");
value = double(value); finite = isfinite(value); value(finite) = value(finite)*factor;
vehicleRequire(~any(isinf(value),"all"),"Length conversion overflow.");
end
