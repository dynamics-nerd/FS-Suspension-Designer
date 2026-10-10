function p = designParameterCore(input)
%DESIGNPARAMETERCORE Separate design role from the existing provenance concepts.
template = struct("id",[],"quantity",[],"unit",[],"scope",[],"type",[], ...
    "value",[],"bounds",[],"binding","NONE","comparisonTolerance",[], ...
    "availability","NOT_PROVIDED","sourceKind","UNSPECIFIED","sourceNote","", ...
    "ruleReference",struct(),"derivationReference","","description","","metadata",struct());
d = designDefinition(input,template,["id","quantity","unit","scope","type"]);
d.id = designText(d.id); d.type = designText(d.type); d.binding = designText(d.binding);
designRequire(any(d.type == ["KNOWN","FIXED","RANGE","FREE","TARGET","DERIVED","ASSUMED","RULE"]),"Unknown parameter role.");
d.scope = fsd.model.designScope(d.scope.kind,d.scope.id,d.scope.cornerId);
[~,canonical] = fsd.model.convertDesignUnits([],d.quantity,d.unit);
designRequire(string(d.unit) == canonical,"Definition must be in canonical units.");
d.quantity = string(d.quantity); d.unit = canonical;
designRequire(isnumeric(d.value) && isreal(d.value) && ...
    (isempty(d.value) || (isscalar(d.value) && isfinite(d.value))),"Parameter value must be empty or finite scalar.");
designRequire(isnumeric(d.bounds) && isreal(d.bounds) && (isempty(d.bounds) || ...
    (isequal(size(d.bounds),[1,2]) && all(isfinite(d.bounds)) && d.bounds(1) <= d.bounds(2))),"Invalid parameter bounds.");
if ~isempty(d.value) && ~isempty(d.bounds)
    designRequire(d.value >= d.bounds(1) && d.value <= d.bounds(2),"Parameter outside its supplied bounds.");
end
d.availability = designText(d.availability); d.sourceKind = designText(d.sourceKind);
available = any(d.availability == ["KNOWN","ASSUMED","DERIVED"]);
designRequire(any(d.availability == ["NOT_PROVIDED","NOT_APPLICABLE","KNOWN","ASSUMED", ...
    "DERIVED","PENDING_CALCULATION","INVALID"]),"Unknown availability.");
designRequire(available == ~isempty(d.value),"Availability/value mismatch; unknown is not zero.");
designRequire(any(d.sourceKind == ["KNOWN","ASSUMED","DERIVED","UNSPECIFIED"]),"Invalid provenance.");
if available
    designRequire(d.sourceKind == d.availability,"Known/assumed/derived provenance mismatch.");
    designRequire(strlength(string(d.sourceNote)) > 0,"Available values need a provenance note.");
end
if d.type == "DERIVED" && available
    designRequire(d.availability == "DERIVED" && strlength(string(d.derivationReference)) > 0, ...
        "Derived data require a calculation reference.");
elseif d.type == "ASSUMED" && available
    designRequire(d.availability == "ASSUMED","Assumed input cannot be reported as measured.");
end
hp = any(d.binding == ["HARDPOINT_X","HARDPOINT_Y","HARDPOINT_Z"]);
other = any(d.binding == ["SPRING_RATE","SPRING_PRELOAD","VEHICLE_WHEELBASE", ...
    "VEHICLE_FRONT_TRACK","VEHICLE_REAR_TRACK","VEHICLE_MASS"]);
designRequire(d.binding == "NONE" || hp || other,"Unknown parameter binding.");
if hp, designRequire(d.scope.kind == "HARDPOINT" && d.quantity == "LENGTH","Hardpoint coordinate needs length/hardpoint scope."); end
if d.binding == "SPRING_RATE", designRequire(d.scope.kind == "COMPONENT" && d.quantity == "STIFFNESS","Spring rate binding mismatch."); end
if d.binding == "SPRING_PRELOAD", designRequire(d.scope.kind == "COMPONENT" && d.quantity == "LENGTH","Preload binding mismatch."); end
if startsWith(d.binding,"VEHICLE_")
    expected = "LENGTH"; if d.binding == "VEHICLE_MASS", expected = "MASS"; end
    designRequire(d.scope.kind == "VEHICLE" && d.quantity == expected,"Vehicle binding mismatch.");
end
if d.type == "FIXED" && d.binding ~= "NONE"
    designRequire(available && isnumeric(d.comparisonTolerance) && isreal(d.comparisonTolerance) && ...
        isscalar(d.comparisonTolerance) && isfinite(d.comparisonTolerance) && d.comparisonTolerance >= 0, ...
        "Bound FIXED input needs value and explicit comparison tolerance.");
elseif ~isempty(d.comparisonTolerance)
    designRequire(isscalar(d.comparisonTolerance) && isreal(d.comparisonTolerance) && ...
        isfinite(d.comparisonTolerance) && d.comparisonTolerance >= 0,"Invalid comparison tolerance.");
end
if d.type == "RANGE", designRequire(~isempty(d.bounds),"RANGE needs an explicit interval."); end
if d.type == "RULE"
    fields = ["organizer","version","ruleId","quantity","source","status","applicability"];
    designRequire(isstruct(d.ruleReference) && isscalar(d.ruleReference) && ...
        all(isfield(d.ruleReference,fields)),"RULE needs a concrete structured reference.");
    for field = fields
        v = string(d.ruleReference.(field));
        designRequire(isscalar(v) && ~ismissing(v) && strlength(v) > 0,"Incomplete rule reference.");
    end
    designRequire(string(d.ruleReference.quantity) == d.quantity,"Rule quantity mismatch.");
end
p = designRecord("DesignParameter",d);
end
