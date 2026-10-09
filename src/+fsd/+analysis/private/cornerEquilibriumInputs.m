function options = cornerEquilibriumInputs(model, actuation, mechanical, demand, input)
%CORNEREQUILIBRIUMINPUTS Validate once; the search only consumes existing samples.
id = "fsd:analysis:InvalidCornerEquilibrium";
if ~isempty(actuation)
    fsd.model.validateActuationGeometry(actuation);
    if ~isequal(model.actuationIdentity,actuation.identity)
        error(id,"Actuation belongs to a different corner/model.");
    end
end
fsd.analysis.validateSpringDamperSweepAnalysis(mechanical,model,actuation);
if ~isnumeric(demand) || ~isreal(demand) || ~isscalar(demand) || ~isfinite(demand) || demand < 0
    error(id,"Support demand must be explicit, finite nonnegative N.");
end
if any(mechanical.inputWheelVelocity_m_per_s ~= 0)
    error(id,"Static equilibrium requires a mechanical path evaluated at rest.");
end
z = mechanical.achievedWheelTravel_m; finite = z(isfinite(z));
if isempty(finite), interval = [0,0]; else, interval = [min(finite),max(finite)]; end
options = struct("travelInterval_m",interval,"forceAbsoluteTolerance_N",1e-8, ...
    "forceRelativeTolerance",1e-10,"stiffnessZeroTolerance_N_per_m",1e-8*model.spring.rate_N_per_m, ...
    "rootSelection","UNIQUE_ONLY","referenceTravel_m",NaN, ...
    "demandSourceKind","UNSPECIFIED","demandSourceNote","Explicit support input in N");
if ~isstruct(input) || ~isscalar(input) || ...
        ~isempty(setdiff(fieldnames(input),fieldnames(options)))
    error(id,"Invalid/unknown equilibrium options.");
end
names = fieldnames(input);
for i = 1:numel(names), options.(names{i}) = input.(names{i}); end
interval = options.travelInterval_m;
if ~isnumeric(interval) || ~isreal(interval) || ~isequal(size(interval),[1,2]) || ...
        any(~isfinite(interval)) || interval(1) > interval(2)
    error(id,"Invalid travel interval.");
end
for name = ["forceAbsoluteTolerance_N","forceRelativeTolerance","stiffnessZeroTolerance_N_per_m"]
    value = options.(name);
    if ~isnumeric(value) || ~isreal(value) || ~isscalar(value) || ~isfinite(value) || value < 0
        error(id,"Invalid numeric equilibrium budget.");
    end
end
options.rootSelection = scalarText(options.rootSelection,id);
options.demandSourceKind = scalarText(options.demandSourceKind,id);
options.demandSourceNote = scalarText(options.demandSourceNote,id);
if ~any(options.demandSourceKind == ["KNOWN","FIXED","RANGE","FREE","TARGET", ...
        "DERIVED","ASSUMED","RULE","UNSPECIFIED"]) || ...
        ~any(options.rootSelection == ["UNIQUE_ONLY","NEAREST_REFERENCE"])
    error(id,"Invalid demand provenance or root selection.");
end
if options.rootSelection == "NEAREST_REFERENCE"
    value = options.referenceTravel_m;
    if ~isnumeric(value) || ~isreal(value) || ~isscalar(value) || ~isfinite(value)
        error(id,"Nearest-reference selection requires explicit reference travel.");
    end
elseif ~isequaln(options.referenceTravel_m,NaN)
    error(id,"Reference is unused with UNIQUE_ONLY.");
end
end

function value = scalarText(value,id)
if ~((isstring(value) && isscalar(value) && ~ismissing(value)) || (ischar(value) && isrow(value)))
    error(id,"Expected scalar text.");
end
value = string(value);
if strlength(value) == 0, error(id,"Empty text."); end
end
