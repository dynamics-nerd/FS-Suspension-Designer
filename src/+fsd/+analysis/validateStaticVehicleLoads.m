function valid = validateStaticVehicleLoads(result, vehicle, loadCase)
%VALIDATESTATICVEHICLELOADS Reconstruct family, closure, measurements and support.
id = "fsd:analysis:InvalidStaticLoads";
if ~isstruct(result) || ~isscalar(result) || ~isfield(result,"loadCase")
    error(id,"Invalid load result.");
end
if nargin < 3, loadCase = result.loadCase; end
fsd.model.validateVehicleLoadCase(loadCase,vehicle);
expected = staticLoadCore(vehicle,loadCase);
if ~isfield(result,"elapsedTime_s") || ~isnumeric(result.elapsedTime_s) || ...
        ~isscalar(result.elapsedTime_s) || ~isfinite(result.elapsedTime_s) || result.elapsedTime_s < 0 || ...
        ~isequaln(rmfield(result,"elapsedTime_s"),rmfield(expected,"elapsedTime_s"))
    error(id,"Inconsistent static load payload.");
end
valid = true;
end
