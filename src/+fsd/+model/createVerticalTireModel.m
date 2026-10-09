function tire = createVerticalTireModel(definition, units)
%CREATEVERTICALTIREMODEL Explicit optional compression-only vertical tire.
id = "fsd:model:InvalidVerticalTireModel";
required = ["cornerId","modelType","stiffness","unloadedRadius","sourceKind","sourceNote"];
if ~isstruct(definition) || ~isscalar(definition) || ~all(isfield(definition,required)) || ...
        ~isempty(setdiff(fieldnames(definition),cellstr(required))) || ...
        ~isstruct(units) || ~isscalar(units) || ~all(isfield(units,["length","stiffness"]))
    error(id,"Complete explicit definition and units required.");
end
d = definition;
for name = ["cornerId","modelType","sourceKind","sourceNote"]
    value = d.(name);
    if ~((isstring(value) && isscalar(value) && ~ismissing(value)) || (ischar(value) && isrow(value)))
        error(id,"Expected scalar text.");
    end
    d.(name) = string(value);
end
if ~any(d.cornerId == ["FL","FR","RL","RR"]) || ...
        d.modelType ~= "LINEAR_VERTICAL_UNILATERAL" || ...
        ~any(d.sourceKind == ["KNOWN","ASSUMED","FIXED","DERIVED"]) || strlength(d.sourceNote) == 0
    error(id,"Invalid corner, law or provenance.");
end
for name = ["stiffness","unloadedRadius"]
    value = d.(name);
    if ~isnumeric(value) || ~isreal(value) || ~isscalar(value) || ~isfinite(value) || value <= 0
        error(id,"Positive finite stiffness/radius required.");
    end
end
k = fsd.model.convertMechanicalUnits(d.stiffness,"springRate",units.stiffness,"N/m");
r = fsd.model.convertLengthToMetres(d.unloadedRadius,units.length);
if ~isnumeric(k) || ~isreal(k) || ~isscalar(k) || ~isfinite(k) || k <= 0 || ...
        ~isnumeric(r) || ~isreal(r) || ~isscalar(r) || ~isfinite(r) || r <= 0
    error(id,"Positive finite stiffness and radius required; no default stiffness.");
end
tire = struct("schemaVersion","0.10.0","kind","VerticalTireModel", ...
    "cornerId",d.cornerId,"modelType",d.modelType,"stiffness_N_per_m",k, ...
    "unloadedRadius_m",r,"sourceKind",d.sourceKind,"sourceNote",d.sourceNote);
tire.identity = rmfield(tire,["sourceKind","sourceNote"]);
end
