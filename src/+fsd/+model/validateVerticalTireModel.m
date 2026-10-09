function valid = validateVerticalTireModel(tire)
%VALIDATEVERTICALTIREMODEL Reconstruct canonical parameters and identity.
id = "fsd:model:InvalidVerticalTireModel";
if ~isstruct(tire) || ~isscalar(tire) || ~all(isfield(tire, ...
        ["cornerId","modelType","stiffness_N_per_m","unloadedRadius_m","sourceKind","sourceNote"]))
    error(id,"Incomplete vertical tire.");
end
d = struct("cornerId",tire.cornerId,"modelType",tire.modelType, ...
    "stiffness",tire.stiffness_N_per_m,"unloadedRadius",tire.unloadedRadius_m, ...
    "sourceKind",tire.sourceKind,"sourceNote",tire.sourceNote);
expected = fsd.model.createVerticalTireModel(d,struct("length","m","stiffness","N/m"));
if ~isequaln(tire,expected), error(id,"Inconsistent tire payload/identity."); end
valid = true;
end
