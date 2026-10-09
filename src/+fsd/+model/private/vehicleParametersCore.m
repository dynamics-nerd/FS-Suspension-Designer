function vehicle = vehicleParametersCore(input)
%VEHICLEPARAMETERSCORE Canonical SI mass bookkeeping; no suspension dependency.
required = ["wheelbase","frontTrack","rearTrack","gravity_mps2", ...
    "operatingConfiguration","massMode","sourceKind"];
allowed = [required,"totalMass","cg","components","includes", ...
    "frontWeightFraction","rearWeightFraction","unsprungMass","contactPoints","contactSourceKind"];
vehicleRequire(isstruct(input) && isscalar(input) && all(isfield(input,required)) ...
    && isempty(setdiff(string(fieldnames(input)),allowed)),"Incomplete/unknown definition field.");
d = struct("wheelbase",vehicleValue(input.wheelbase,1,false), ...
    "frontTrack",vehicleValue(input.frontTrack,1,false), ...
    "rearTrack",vehicleValue(input.rearTrack,1,false), ...
    "gravity_mps2",vehicleValue(input.gravity_mps2,1,false), ...
    "operatingConfiguration",vehicleText(input.operatingConfiguration), ...
    "massMode",vehicleText(input.massMode),"sourceKind",vehicleText(input.sourceKind));
vehicleRequire(all([d.wheelbase,d.frontTrack,d.rearTrack,d.gravity_mps2] > 0), ...
    "Dimensions and gravity must be positive.");
kinds = ["KNOWN","FIXED","RANGE","FREE","TARGET","DERIVED","ASSUMED","RULE","UNSPECIFIED"];
vehicleRequire(any(d.sourceKind == kinds),"Invalid provenance.");
d.totalMass = NaN; d.cg = nan(1,3); d.components = struct([]);
d.includes = strings(1,0); d.frontWeightFraction = NaN; d.rearWeightFraction = NaN;
d.unsprungMass = nan(1,4);
if isfield(input,"unsprungMass"), d.unsprungMass = vehicleValue(input.unsprungMass,4,true); end
vehicleRequire(all(d.unsprungMass(isfinite(d.unsprungMass)) >= 0),"Negative unsprung mass.");
if d.massMode == "TOTAL_MASS"
    vehicleRequire(isfield(input,"totalMass") && isfield(input,"includes") && ...
        (~isfield(input,"components") || isempty(input.components)), ...
        "TOTAL_MASS requires inclusion inventory and excludes component additions.");
    d.totalMass = vehicleValue(input.totalMass,1,false);
    vehicleRequire(d.totalMass > 0,"Total mass must be positive.");
    d.includes = inventory(input.includes);
    if isfield(input,"cg"), d.cg = vehicleValue(input.cg,3,true); end
    mass = d.totalMass; cg = d.cg; massKind = d.sourceKind;
    cgKind = repmat(d.sourceKind,1,3);
elseif d.massMode == "COMPONENT_MASSES"
    vehicleRequire(isfield(input,"components") && isstruct(input.components) && ...
        ~isempty(input.components) && (~isfield(input,"totalMass") || isequaln(input.totalMass,NaN)) && ...
        (~isfield(input,"cg") || isequaln(input.cg,nan(1,3))) && ...
        (~isfield(input,"includes") || isempty(input.includes)), ...
        "Component mode excludes a separate total/CG/inventory.");
    components = input.components(:); ids = strings(numel(components),1);
    used = strings(1,0); weights = zeros(numel(components),1); positions = nan(numel(components),3);
    canonical = cell(numel(components),1);
    for i = 1:numel(components)
        c = components(i);
        vehicleRequire(all(isfield(c,["id","mass","includes","sourceKind"])) && ...
            isempty(setdiff(string(fieldnames(c)),["id","mass","cg","includes","sourceKind"])), ...
            "Invalid component definition.");
        ids(i) = vehicleText(c.id); weights(i) = vehicleValue(c.mass,1,false);
        vehicleRequire(weights(i) > 0,"Component mass must be positive; omit absent components.");
        items = inventory(c.includes);
        vehicleRequire(isempty(intersect(used,items)),"An included item is counted in two components.");
        used = [used,items]; %#ok<AGROW>
        if isfield(c,"cg"), positions(i,:) = vehicleValue(c.cg,3,true); end
        sourceKind = vehicleText(c.sourceKind);
        vehicleRequire(any(sourceKind == kinds),"Invalid component provenance.");
        canonical{i} = struct("id",ids(i),"mass",weights(i),"cg",positions(i,:), ...
            "includes",items,"sourceKind",sourceKind);
    end
    vehicleRequire(numel(unique(ids)) == numel(ids),"Duplicate component IDs.");
    d.components = vertcat(canonical{:}); mass = sum(weights);
    vehicleRequire(isfinite(mass),"Mass arithmetic overflow.");
    cg = nan(1,3); available = all(isfinite(positions),1);
    cg(available) = (weights'/mass)*positions(:,available);
    massKind = "DERIVED"; cgKind = repmat("DERIVED",1,3);
else
    vehicleRequire(false,"Unknown mass mode.");
end
for name = ["frontWeightFraction","rearWeightFraction"]
    if isfield(input,name), d.(name) = vehicleValue(input.(name),1,true); end
end
f = d.frontWeightFraction; r = d.rearWeightFraction;
vehicleRequire((isnan(f) || (f >= 0 && f <= 1)) && ...
    (isnan(r) || (r >= 0 && r <= 1)),"Weight fractions must be in [0,1].");
tol = 1e-10; % documented numerical consistency, not instrumentation tolerance
if isfinite(f) && isfinite(r), vehicleRequire(abs(f+r-1) <= tol,"Contradictory axle fractions."); end
xFromFraction = NaN;
if isfinite(r) || isfinite(f)
    xFront = 0; xRear = d.wheelbase;
    if isfield(input,"contactPoints")
        points = input.contactPoints;
        vehicleRequire(isnumeric(points) && isreal(points) && isequal(size(points),[4,3]) && ...
            all(isfinite(points),"all"),"Invalid fraction contact geometry.");
        vehicleRequire(abs(points(1,1)-points(2,1)) <= tol*max(d.wheelbase,1) && ...
            abs(points(3,1)-points(4,1)) <= tol*max(d.wheelbase,1) && ...
            points(3,1) > points(1,1),"Axle fractions cannot specify CG for staggered axle lines.");
        xFront = points(1,1); xRear = points(3,1);
    end
    if isfinite(r), fractionRear = r; else, fractionRear = 1-f; end
    xFromFraction = xFront+fractionRear*(xRear-xFront);
end
if isfinite(xFromFraction)
    if isfinite(cg(1))
        vehicleRequire(abs(cg(1)-xFromFraction) <= tol*max(d.wheelbase,1), ...
            "CG contradicts weight fraction.");
    elseif d.massMode == "TOTAL_MASS"
        cg(1) = xFromFraction; cgKind(1) = "DERIVED";
    else
        vehicleRequire(false,"Missing component CG cannot be replaced by a total fraction.");
    end
end
cgKind(~isfinite(cg)) = "UNAVAILABLE";
vehicleRequire(~any(isinf(cg)) && sum(d.unsprungMass(isfinite(d.unsprungMass))) <= mass, ...
    "Unsprung sum exceeds total mass.");
sprung = NaN;
if all(isfinite(d.unsprungMass)), sprung = mass-sum(d.unsprungMass); end
d.contactPoints = [0,-d.frontTrack/2,0;0,d.frontTrack/2,0; ...
    d.wheelbase,-d.rearTrack/2,0;d.wheelbase,d.rearTrack/2,0];
contactKind = "ASSUMED_CONCEPTUAL";
if isfield(input,"contactPoints")
    p = input.contactPoints;
    vehicleRequire(isnumeric(p) && isreal(p) && isequal(size(p),[4,3]) && ...
        all(isfinite(p),"all"),"Contact points must be finite 4-by-3, FL/FR/RL/RR.");
    d.contactPoints = double(p); contactKind = d.sourceKind;
end
if isfield(input,"contactSourceKind")
    contactKind = vehicleText(input.contactSourceKind);
    vehicleRequire(any(contactKind == [kinds,"ASSUMED_CONCEPTUAL"]),"Invalid contact provenance.");
end
d.contactSourceKind = contactKind;
p = d.contactPoints; scale = max([d.wheelbase,d.frontTrack,d.rearTrack,max(abs(p(:)))]);
vehicleRequire(all(abs(p(:,3)) <= 1e-10*scale) && p(1,2) < p(2,2) && ...
    p(3,2) < p(4,2) && all(p([1,3],2) < 0) && all(p([2,4],2) > 0), ...
    "Contacts must be on nominal horizontal ground, with left negative/right positive Y.");
singular = svd([ones(1,4);p(:,1)'/scale;p(:,2)'/scale]);
vehicleRequire(singular(3)/singular(1) > sqrt(eps),"Degenerate/ill-conditioned support layout.");
vehicle = struct("schemaVersion","0.9.0","kind","VehicleParameters", ...
    "coordinateSystem","X_REAR_Y_RIGHT_Z_UP","cornerIds",["FL";"FR";"RL";"RR"], ...
    "definitionSI",d,"totalMass_kg",mass,"cg_m",cg,"massSourceKind",massKind, ...
    "cgSourceKind",cgKind,"unsprungMass_kg",d.unsprungMass(:), ...
    "sprungMass_kg",sprung,"contactPoints_m",p,"contactSourceKind",contactKind, ...
    "metadata",struct);
vehicle.identity = struct("schemaVersion","1.0.0","kind","VehicleParametersIdentity", ...
    "definitionSI",d,"totalMass_kg",mass,"cg_m",cg, ...
    "coordinateSystem",vehicle.coordinateSystem);
end

function items = inventory(value)
vehicleRequire(isstring(value) || ischar(value) || iscellstr(value),"Invalid inclusion inventory.");
items = reshape(string(value),1,[]);
vehicleRequire(~isempty(items) && ~any(ismissing(items)) && all(strlength(items) > 0) ...
    && numel(unique(items)) == numel(items),"Inventory must contain unique nonempty item IDs.");
end
