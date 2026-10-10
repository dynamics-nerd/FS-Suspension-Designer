function catalog = designMetricCatalog()
%DESIGNMETRICCATALOG Explicit supported metrics; no arbitrary field-path lookup.
% Source/independent-variable pairs are positional, never inferred from sample count.
rows = {
    "CAMBER","ANGLE","CORNER",["BUMP","ROLL"],["WHEEL_TRAVEL","ROLL_ANGLE"],"Negative top inward";
    "ROAD_CAMBER","ANGLE","CORNER","ROLL","ROLL_ANGLE","Historical camber sign in road frame";
    "TOE","ANGLE","CORNER",["BUMP","RACK","ROLL"],["WHEEL_TRAVEL","RACK_TRAVEL","ROLL_ANGLE"],"Positive toe-in";
    "BUMP_STEER","ANGLE","CORNER","BUMP","WHEEL_TRAVEL","toe(z)-staticToe, even without zero sample";
    "CASTER","ANGLE","CORNER","BUMP","WHEEL_TRAVEL","UBJ rearward positive";
    "KPI","ANGLE","CORNER","BUMP","WHEEL_TRAVEL","UBJ inward positive";
    "ROAD_WHEEL_ANGLE","ANGLE","CORNER","RACK","RACK_TRAVEL","Positive heading toward +Y";
    "SCRUB_RADIUS","LENGTH","CORNER","RACK","RACK_TRAVEL","Contact outboard positive";
    "MECHANICAL_TRAIL","LENGTH","CORNER","RACK","RACK_TRAVEL","Axis-ground intersection forward positive";
    "ACKERMANN_ANGLE_ERROR","ANGLE","AXLE","RACK","RACK_TRAVEL","Wrapped actualOuter-idealOuter, not percentage";
    "ROLL_CENTER_HEIGHT","LENGTH","AXLE","ROLL","ROLL_ANGLE","Height above common contact level only";
    "ROLL_CENTER_ROAD_HEIGHT","LENGTH","AXLE","ROLL","ROLL_ANGLE","Signed perpendicular distance to road";
    "ROLL_CENTER_Y","LENGTH","AXLE","ROLL","ROLL_ANGLE","Chassis Y coordinate, right positive";
    "WHEEL_CENTER_TRACK_CHANGE","LENGTH","AXLE","ROLL","ROLL_ANGLE","Change from h=0,phi=0 reference";
    "DAMPER_COMPRESSION","LENGTH","CORNER",["ACTUATION","MECHANICAL"],["WHEEL_TRAVEL","WHEEL_TRAVEL"],"Positive shortening from nominal";
    "MOTION_RATIO","RATIO","CORNER",["ACTUATION","MECHANICAL"],["WHEEL_TRAVEL","WHEEL_TRAVEL"],"Signed dc/dz";
    "INSTALLATION_RATIO","RATIO","CORNER",["ACTUATION","MECHANICAL"],["WHEEL_TRAVEL","WHEEL_TRAVEL"],"Absolute MR, not reciprocal";
    "SPRING_AXIAL_FORCE","FORCE","CORNER","MECHANICAL","WHEEL_TRAVEL","Nonnegative axial compression magnitude";
    "SPRING_WHEEL_RESISTANCE","FORCE","CORNER","MECHANICAL","WHEEL_TRAVEL","Signed Fs*MR, not tire normal load";
    "TANGENT_WHEEL_RATE","STIFFNESS","CORNER","MECHANICAL","WHEEL_TRAVEL","Complete elastic+geometric rate; negative retained";
    "CORNER_LOAD","FORCE","CORNER",["STATIC_LOADS","GLOBAL_STATIC"],["NONE","NONE"],"Upward tire normal; v0.9 requires available closure";
    "CROSSWEIGHT","FRACTION","VEHICLE",["STATIC_LOADS","GLOBAL_STATIC"],["NONE","NONE"],"(FR+RL)/(M*g) v0.9, /sum(N) global; sources distinct";
    "REFERENCE_HEIGHT","LENGTH","VEHICLE","GLOBAL_STATIC","NONE","World Z of explicitly named chassis reference point"};
template = struct("id","","quantity","","unit","","scopeKind","", ...
    "sourceTypes",strings(0,1),"independentVariables",strings(0,1), ...
    "valueKinds",strings(0,1),"signConvention","","prerequisites","","validity","" );
catalog = repmat(template,size(rows,1),1);
for i = 1:size(rows,1)
    [~,unit] = fsd.model.convertDesignUnits([],rows{i,2},canonical(rows{i,2}));
    sources = rows{i,4}; variables = rows{i,5}; kinds = repmat("CURVE",size(variables));
    kinds(variables == "NONE") = "SCALAR";
    catalog(i) = struct("id",rows{i,1},"quantity",rows{i,2},"unit",unit, ...
        "scopeKind",rows{i,3},"sourceTypes",sources,"independentVariables",variables, ...
        "valueKinds",kinds,"signConvention",rows{i,6}, ...
        "prerequisites","Matching validated model/result source, scope and reference", ...
        "validity","Native convergence/conditioning/quality gates; finite values only; sampled, not continuous");
    if any(sources == "RACK")
        catalog(i).prerequisites = "SteeringSystemGeometry + RackSweepResult + RackSweepAnalysis; fixed left/right wheel travel";
    elseif any(sources == "GLOBAL_STATIC")
        catalog(i).prerequisites = "Validated selected GlobalStaticEquilibriumResult, or explicitly closed v0.9 loads when supported";
    elseif any(sources == "MECHANICAL")
        catalog(i).prerequisites = "Validated SpringDamperModel and native mechanical path/result with feasible provided limits";
    end
    if rows{i,1} == "TANGENT_WHEEL_RATE"
        catalog(i).prerequisites = catalog(i).prerequisites+"; reliable MR and second derivative, not elastic rate alone";
    elseif rows{i,1} == "REFERENCE_HEIGHT"
        catalog(i).prerequisites = catalog(i).prerequisites+"; explicitly named chassis reference point";
    end
end
end

function unit = canonical(quantity)
switch quantity
    case "ANGLE", unit = "rad";
    case "LENGTH", unit = "m";
    case "FORCE", unit = "N";
    case "STIFFNESS", unit = "N/m";
    otherwise, unit = "1";
end
end
