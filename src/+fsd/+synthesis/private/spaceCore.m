function space = spaceCore(seed,specification,plan)
%SPACECORE Canonical definition; no solves, inferred bounds or physical presets.
fsd.model.validateDoubleWishboneGeometry(seed);
fsd.model.validateDesignSpecification(specification);
requireSynthesis(isstruct(plan) && isscalar(plan) && isfield(plan,'travel_m') && ...
    all(ismember(string(fieldnames(plan)),["travel_m","solverOptions"])), 'Explicit BUMP plan required.');
z = plan.travel_m;
requireSynthesis(isnumeric(z) && isreal(z) && isvector(z) && ~isempty(z) && all(isfinite(z)), 'Finite BUMP grid required.');
z = double(z(:));
requireSynthesis(isscalar(z) || all(diff(z)>0) || all(diff(z)<0),'BUMP grid must be strictly monotonic.');
if ~isfield(plan,'solverOptions'), plan.solverOptions = struct(); end
plan = struct('travel_m',z,'solverOptions',fsd.kinematics.solverSettings(plan.solverOptions));
declared = fsd.model.designVariableSpace(specification,true);
variables = cell(size(declared.variables)); lower = zeros(numel(variables),1); upper = lower; initial = lower;
keys = strings(numel(variables),1);
supported = seed.cornerId + "_" + ["UCA_FWD_CHASSIS","UCA_AFT_CHASSIS","LCA_FWD_CHASSIS","LCA_AFT_CHASSIS"];
parameters = specification.definitionSI.parameters;
for i = 1:numel(parameters)
    p = parameters{i}.definitionSI;
    if p.binding ~= "NONE" && any(p.type == ["FIXED","FREE","RANGE"])
        requireSynthesis(startsWith(p.binding,'HARDPOINT_') && p.scope.cornerId == seed.cornerId && ...
            ismember(p.scope.id,seed.hardpoints.ids),'Unsupported bound parameter/corner/hardpoint.');
    end
    if p.type == "FIXED" && p.binding ~= "NONE"
        axis = ["HARDPOINT_X","HARDPOINT_Y","HARDPOINT_Z"] == p.binding;
        point = fsd.model.getPoint(seed,p.scope.id);
        requireSynthesis(abs(point(axis)-p.value)<=p.comparisonTolerance,'Seed contradicts FIXED parameter.');
    end
end
for i = 1:numel(variables)
    p = declared.variables{i}; axis = find(["HARDPOINT_X","HARDPOINT_Y","HARDPOINT_Z"] == p.binding);
    requireSynthesis(isscalar(axis) && p.unit == "m" && ismember(p.scope.id,supported), 'Only XYZ of UCA/LCA chassis pivots supported.');
    row = find(seed.hardpoints.ids == p.scope.id); initial(i) = seed.hardpoints.xyz_m(row,axis);
    lower(i) = p.bounds(1); upper(i) = p.bounds(2);
    requireSynthesis(initial(i)>=lower(i) && initial(i)<=upper(i),'Seed coordinate outside bounds.');
    if ~isempty(p.value), requireSynthesis(p.value==initial(i),'Initial parameter value must equal seed coordinate.'); end
    for j = 1:numel(parameters)
        fixed = parameters{j}.definitionSI;
        if fixed.type == "FIXED" && fixed.scope.id == p.scope.id && fixed.binding == p.binding
            requireSynthesis(lower(i)==upper(i),'FIXED coordinate cannot be a moving variable.');
        end
    end
    keys(i) = p.scope.id+":"+p.binding;
    variables{i} = struct('id',p.id,'cornerId',seed.cornerId,'hardpointId',p.scope.id, ...
        'component',extractAfter(p.binding,'HARDPOINT_'),'row',row,'column',axis, ...
        'initial_m',initial(i),'lower_m',lower(i),'upper_m',upper(i),'unit',"m", ...
        'parameter',p,'seedIdentity',fsd.model.geometryIdentity(seed));
end
requireSynthesis(numel(unique(keys))==numel(keys),'Duplicate coordinate binding.');
requireSynthesis(all(isfinite(upper-lower)),'Variable span must be representable.');
constraints = specification.definitionSI.constraints;
for i = 1:numel(constraints)
    c = constraints{i}.definitionSI;
    requireSynthesis(c.scope.cornerId==seed.cornerId && ismember(c.scope.id,seed.hardpoints.ids),'Constraint references missing hardpoint/corner.');
    if c.type == "HARDPOINT_FIXED" && c.strength == "HARD"
        point = fsd.model.getPoint(seed,c.scope.id);
        requireSynthesis(all(abs(point-c.position)<=c.comparisonTolerance),'Seed contradicts FIXED point.');
        for j = 1:numel(variables)
            if variables{j}.hardpointId == c.scope.id
                requireSynthesis(lower(j)==upper(j),'FIXED point cannot be a moving variable.');
            end
        end
    end
end
targets = specification.definitionSI.targets.definitionSI.targets; sourceIds = strings(0,1);
for i = 1:numel(targets)
    t = targets{i}.definitionSI;
    if t.sourceType ~= "BUMP" || ~ismember(t.metricId,["CAMBER","TOE","BUMP_STEER","CASTER","KPI"]) || ...
            t.scope.id ~= seed.cornerId || ~isempty(t.requiredSourceIdentity)
        error('fsd:synthesis:UnsupportedTarget','Target %s requires unsupported reconstruction %s/%s or a locked source/corner.',t.id,t.sourceType,t.metricId);
    end
    sourceIds(end+1,1) = t.sourceId; %#ok<AGROW>
end
space = struct('schemaVersion',"0.12.0",'kind',"SynthesisDesignSpace", ...
    'seed',seed,'seedIdentity',fsd.model.geometryIdentity(seed),'specification',specification, ...
    'plan',plan,'sourceIds',unique(sourceIds,'stable'),'variables',{variables}, ...
    'lower_m',lower,'upper_m',upper,'initial_m',initial,'active',upper>lower);
end
