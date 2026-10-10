function target = designTargetCore(input)
%DESIGNTARGETCORE Fully defined objectives, independent of any suspension geometry.
template = struct("id",[],"metricId",[],"sourceId",[],"sourceType",[],"scope",[], ...
    "type",[],"strength",[],"unit",[],"independentVariable",[],"xUnit",[], ...
    "x",[],"value",[],"tolerance",[],"lower",[],"upper",[],"normalizationScale",[], ...
    "normalizationNote","","weight",[],"transform","IDENTITY","subjectId","", ...
    "requiredSourceIdentity",[],"sourceNote",[],"numericalTolerance",[], ...
    "physicalUncertainty",[],"conditions",struct(),"metadata",struct());
required = ["id","metricId","sourceId","sourceType","scope","type","strength", ...
    "unit","independentVariable","xUnit","sourceNote"];
d = designDefinition(input,template,required);
for name = ["id","metricId","sourceId","sourceType","type","strength","independentVariable","transform"]
    d.(name) = designText(d.(name));
end
d.scope = fsd.model.designScope(d.scope.kind,d.scope.id,d.scope.cornerId);
catalog = fsd.model.designMetricCatalog; j = find(string({catalog.id}) == d.metricId);
designRequire(isscalar(j),"Unknown metric ID."); metric = catalog(j);
k = find(metric.sourceTypes == d.sourceType);
designRequire(isscalar(k) && d.scope.kind == metric.scopeKind && d.unit == metric.unit && ...
    d.independentVariable == metric.independentVariables(k),"Metric/source/scope/unit/coordinate mismatch.");
if d.sourceType == "RACK" && d.scope.kind == "AXLE"
    designRequire(d.scope.id == "FRONT","Rack metric applies only to FRONT.");
end
if d.sourceType == "RACK"
    designRequire(isstruct(d.conditions) && isscalar(d.conditions) && ...
        isequal(fieldnames(d.conditions),{'wheelTravel_m'}) && ...
        isnumeric(d.conditions.wheelTravel_m) && isreal(d.conditions.wheelTravel_m) && ...
        isequal(size(d.conditions.wheelTravel_m),[1,2]) && all(isfinite(d.conditions.wheelTravel_m)), ...
        "Rack targets require explicit SI fixed wheelTravel_m [left,right].");
elseif d.sourceType == "ROLL"
    designRequire(isstruct(d.conditions) && isscalar(d.conditions) && ...
        isequal(fieldnames(d.conditions),{'axleHeave_m'}) && ...
        isnumeric(d.conditions.axleHeave_m) && isreal(d.conditions.axleHeave_m) && ...
        isscalar(d.conditions.axleHeave_m) && isfinite(d.conditions.axleHeave_m), ...
        "Roll targets require explicit SI fixed axleHeave_m.");
else
    designRequire(isstruct(d.conditions) && isscalar(d.conditions) && ...
        isempty(fieldnames(d.conditions)),"Unexpected fixed conditions.");
end
designRequire(any(d.strength == ["HARD","SOFT"]) && any(d.transform == ["IDENTITY","ABS"]),"Unknown strength/transform.");
designRequire(isscalar(string(d.sourceNote)) && strlength(string(d.sourceNote)) > 0,"Target needs an explicit source note.");
curve = any(d.type == ["CURVE_TARGET","CURVE_BAND"]);
designRequire(any(d.type == ["POINT_TARGET","VALUE_BAND","UPPER_BOUND","LOWER_BOUND","CURVE_TARGET","CURVE_BAND"]),"Unknown target type.");
if d.independentVariable == "NONE"
    designRequire(~curve && isempty(d.x) && d.xUnit == "1","Scalar source has no curve coordinate.");
else
    xu = "m"; if d.independentVariable == "ROLL_ANGLE", xu = "rad"; end
    designRequire(d.xUnit == xu && isnumeric(d.x) && isreal(d.x) && all(isfinite(d.x),"all"),"Invalid independent coordinate/units.");
    if curve
        designRequire(iscolumn(d.x) && numel(d.x) >= 2 && ...
            (all(diff(d.x) > 0) || all(diff(d.x) < 0)),"Curve knots must be strictly monotonic, without duplicates.");
    else
        designRequire(isscalar(d.x),"Scalar comparison on a curve needs one explicit coordinate.");
    end
end
n = 1; if curve, n = numel(d.x); end
for field = ["value","tolerance","lower","upper"]
    v = d.(field);
    designRequire(isnumeric(v) && isreal(v) && (isempty(v) || ...
        (all(isfinite(v),"all") && (isscalar(v) || (curve && isequal(size(v),[n,1]))))),"Invalid target values/bands.");
    if ~isempty(v) && isscalar(v) && curve, d.(field) = repmat(double(v),n,1); end
end
switch d.type
    case {"POINT_TARGET","CURVE_TARGET"}
        designRequire(~isempty(d.value) && ~isempty(d.tolerance) && all(d.tolerance >= 0) && ...
            isempty(d.lower) && isempty(d.upper),"Nominal target requires tolerance, not bounds.");
    case {"VALUE_BAND","CURVE_BAND"}
        designRequire(~isempty(d.lower) && ~isempty(d.upper) && all(d.lower <= d.upper) && ...
            isempty(d.value) && isempty(d.tolerance),"Complete ordered band required.");
    case "UPPER_BOUND"
        designRequire(~isempty(d.upper) && isempty(d.lower) && isempty(d.value) && isempty(d.tolerance),"Upper bound incomplete.");
    case "LOWER_BOUND"
        designRequire(~isempty(d.lower) && isempty(d.upper) && isempty(d.value) && isempty(d.tolerance),"Lower bound incomplete.");
end
if ~isempty(d.normalizationScale)
    designRequire(isnumeric(d.normalizationScale) && isreal(d.normalizationScale) && ...
        isscalar(d.normalizationScale) && isfinite(d.normalizationScale) && ...
        d.normalizationScale > 0 && strlength(string(d.normalizationNote)) > 0,"Explicit positive scale and justification required.");
end
if ~isempty(d.weight)
    designRequire(isnumeric(d.weight) && isreal(d.weight) && isscalar(d.weight) && ...
        isfinite(d.weight) && d.weight > 0,"Weights must be explicitly positive.");
end
for field = ["numericalTolerance","physicalUncertainty"]
    v = d.(field);
    designRequire(isnumeric(v) && isreal(v) && (isempty(v) || ...
        (isscalar(v) && isfinite(v) && v >= 0)),"Invalid optional uncertainty/numerical tolerance.");
end
if d.metricId == "REFERENCE_HEIGHT"
    d.subjectId = designText(d.subjectId);
else
    designRequire(isequal(string(d.subjectId),""),"Unexpected subject ID.");
end
target = designRecord("DesignTarget",d);
end
