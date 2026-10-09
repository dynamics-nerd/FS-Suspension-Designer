function loadCase = createVehicleLoadCase(vehicle, definition, units)
%CREATEVEHICLELOADCASE Define measured/crossweight/assumed/underdetermined loads.
% Units: force N or kg_equivalent (uses this vehicle's gravity);
% crossweight fraction or %. Units are explicit even if a quantity is unused.
if nargin < 3, units = struct("force","N","crossweight","fraction"); end
fsd.model.validateVehicleParameters(vehicle);
vehicleRequire(isstruct(units) && isscalar(units) && all(isfield(units,["force","crossweight"])), ...
    "Invalid load units.");
forceUnit = vehicleText(units.force); cwUnit = vehicleText(units.crossweight);
vehicleRequire(any(forceUnit == ["N","kg_equivalent"]) && ...
    any(cwUnit == ["fraction","%"]),"Unsupported load units.");
vehicleRequire(isstruct(definition) && isscalar(definition),"Invalid load-case definition.");
d = definition; metadata = struct;
if isfield(d,"metadata"), metadata = d.metadata; d = rmfield(d,"metadata"); end
vehicleRequire(isstruct(metadata) && isscalar(metadata),"Invalid metadata.");
if isfield(d,"crossweight")
    vehicleRequire(~isfield(d,"crossweightFraction"),"Two crossweight inputs.");
    d.crossweightFraction = d.crossweight; d = rmfield(d,"crossweight");
    if cwUnit == "%", d.crossweightFraction = d.crossweightFraction/100; end
end
if isfield(d,"measuredCornerLoads")
    vehicleRequire(~isfield(d,"measuredCornerLoads_N"),"Two measured load inputs.");
    d.measuredCornerLoads_N = d.measuredCornerLoads; d = rmfield(d,"measuredCornerLoads");
    if forceUnit == "kg_equivalent", d.measuredCornerLoads_N = d.measuredCornerLoads_N*vehicle.definitionSI.gravity_mps2; end
end
loadCase = vehicleLoadCaseCore(vehicle.identity,d); loadCase.metadata = metadata;
end
