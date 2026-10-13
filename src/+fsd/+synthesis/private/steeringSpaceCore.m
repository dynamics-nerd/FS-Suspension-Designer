function space = steeringSpaceCore(left,right,steering,spec,plan,links)
%STEERINGSPACECORE Native FRONT mechanism with one joint specification/controller.
fsd.model.validateSteeringSystemGeometry(steering);
seedAxle=fsd.model.createAxleGeometry(left,right);
requireSynthesis(seedAxle.axleId=="FRONT" && isequaln(seedAxle,steering.frontAxleGeometry), ...
    'A valid native steering seed must use exactly the supplied FRONT corners and rear reference.');
fsd.model.validateDesignSpecification(spec);
requireSynthesis(isstruct(plan) && isscalar(plan) && all(isfield(plan, ...
    {'leftBump','rightBump','rack','referenceRackTravel_m'})) && ...
    all(ismember(string(fieldnames(plan)),["leftBump","rightBump","roll","rack","referenceRackTravel_m"])), ...
    'Explicit BUMP, RACK and steering reference plans required.');
q0=plan.referenceRackTravel_m;
requireSynthesis(isnumeric(q0) && isreal(q0) && isscalar(q0) && isfinite(q0) && q0==0, ...
    'Native BUMP/ROLL only support referenceRackTravel_m=0; nonzero reference is unsupported.');
r=plan.rack;
requireSynthesis(isstruct(r) && isscalar(r) && all(isfield(r,{'travel_m','wheelTravel_m','travelLimits_m'})) && ...
    all(ismember(string(fieldnames(r)),["travel_m","wheelTravel_m","travelLimits_m","solverOptions"])), ...
    'RACK requires explicit grid, wheel travel and declared travel limits.');
q=r.travel_m;
requireSynthesis(isnumeric(q) && isreal(q) && isvector(q) && ~isempty(q) && all(isfinite(q)), ...
    'Finite nonempty RACK grid required.');
q=double(q(:));
requireSynthesis(isscalar(q) || all(diff(q)>0) || all(diff(q)<0),'RACK grid must be strictly monotonic.');
z=r.wheelTravel_m; limits=r.travelLimits_m;
requireSynthesis(isnumeric(z) && isreal(z) && isvector(z) && numel(z)==2 && all(isfinite(z)), ...
    'Explicit fixed [left,right] wheel travel required.');
requireSynthesis(isnumeric(limits) && isreal(limits) && isvector(limits) && numel(limits)==2 && ...
    all(isfinite(limits)) && limits(1)<=0 && limits(2)>=0 && limits(1)<=limits(2) && ...
    all(q>=limits(1) & q<=limits(2)),'Declared rack limits must contain centered reference and all samples.');
if ~isfield(r,'solverOptions'), r.solverOptions=struct(); end
r=struct('travel_m',q,'wheelTravel_m',double(reshape(z,1,2)), ...
    'travelLimits_m',double(reshape(limits,1,2)),'solverOptions',fsd.kinematics.solverSettings(r.solverOptions));
d=spec.definitionSI; targets=d.targets.definitionSI.targets; baseTargets=cell(0,1); aliases=strings(0,1);
for i=1:numel(targets)
    t=targets{i}.definitionSI;
    if t.sourceType~="RACK", baseTargets{end+1,1}=targets{i}; continue; end %#ok<AGROW>
    supported=(t.scope.kind=="CORNER" && ismember(t.scope.id,["FL","FR"]) && ...
        ismember(t.metricId,["TOE","ROAD_WHEEL_ANGLE","SCRUB_RADIUS","MECHANICAL_TRAIL"])) || ...
        (t.scope.kind=="AXLE" && t.scope.id=="FRONT" && t.metricId=="ACKERMANN_ANGLE_ERROR");
    if ~supported || ~isempty(t.requiredSourceIdentity)
        error('fsd:synthesis:UnsupportedTarget','Target %s is not a reconstructible native FRONT RACK target.',t.id);
    end
    requireSynthesis(isequaln(t.conditions.wheelTravel_m,r.wheelTravel_m),'RACK target wheel travel differs from execution plan.');
    aliases(end+1,1)=t.sourceId; %#ok<AGROW>
end
sub=d; sub.targets=fsd.model.createSuspensionDesignTargets(baseTargets);
% This projection only builds axle bindings; the joint assessment retains spec.
if ~any(cellfun(@(target) target.definitionSI.strength=="SOFT",baseTargets))
    sub.compositeScore=false;
end
basePlan=rmfield(plan,{'rack','referenceRackTravel_m'});
space=axleSpaceCore(left,right,fsd.model.createDesignSpecification(sub),basePlan,links, ...
    ["TIE_ROD_INBOARD","TIE_ROD_OUTBOARD"]);
space.schemaVersion="0.14.0"; space.kind="SteeringSynthesisDesignSpace";
space.seedSteering=steering; space.specification=spec; space.plan.rack=r; space.plan.referenceRackTravel_m=double(q0);
aliases=unique(aliases,'stable'); if isempty(aliases), aliases="SYNTH_RACK_FRONT"; end
space.sourceIds{4}=aliases; allIds=vertcat(space.sourceIds{:});
requireSynthesis(numel(unique(allIds))==numel(allIds),'Source aliases cannot cross corners or physical families.');
end
