function valid = validateGlobalStaticSystem(system)
%VALIDATEGLOBALSTATICSYSTEM Structural/physical model check, no analysis dependency.
id = "fsd:model:InvalidGlobalStaticSystem";
if ~isstruct(system) || ~isscalar(system) || ~all(isfield(system, ...
        ["vehicle","loadCase","sources","tires","options"]))
    error(id,"Incomplete system.");
end
if isfield(system,'antiRollBars')
    expected=fsd.model.createGlobalStaticSystem(system.vehicle,system.loadCase,system.sources,system.tires,system.options,system.antiRollBars);
else
    expected=fsd.model.createGlobalStaticSystem(system.vehicle,system.loadCase,system.sources,system.tires,system.options);
end
if ~isequaln(expected,system), error(id,"Inconsistent system identity/payload."); end
valid = true;
end
