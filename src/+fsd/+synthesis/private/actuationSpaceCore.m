function space = actuationSpaceCore(seed,actuation,mechanical,spec,plan)
%ACTUATIONSPACECORE Fixed suspension and explicitly authorized nominal actuation coordinates.
fsd.model.validateDoubleWishboneGeometry(seed); fsd.model.validateActuationGeometry(actuation);
fsd.model.validateDesignSpecification(spec);
requireSynthesis(isequaln(actuation.cornerGeometryIdentity,fsd.model.geometryIdentity(seed)), ...
    'Actuation seed must belong to the supplied suspension seed.');
if ~isempty(mechanical)
    fsd.model.validateSpringDamperModel(mechanical);
    requireSynthesis(isequaln(mechanical.actuationIdentity,actuation.identity),'Mechanical seed must match actuation seed.');
end
requireSynthesis(isstruct(plan) && isscalar(plan) && isfield(plan,'travel_m') && ...
    all(ismember(string(fieldnames(plan)),["travel_m","solverOptions","wheelVelocity_m_per_s"])), ...
    'Explicit wheel travel plan required.');
z=plan.travel_m;
requireSynthesis(isnumeric(z) && isreal(z) && isvector(z) && ~isempty(z) && all(isfinite(z)), ...
    'Finite nonempty wheel travel grid required.');
z=double(z(:)); requireSynthesis(isscalar(z) || all(diff(z)>0) || all(diff(z)<0),'Wheel travel must be strictly monotonic.');
if ~isfield(plan,'solverOptions'), plan.solverOptions=struct(); end
velocity=[];
if ~isempty(mechanical)
    requireSynthesis(isfield(plan,'wheelVelocity_m_per_s'),'Mechanical analysis requires explicitly prescribed wheel velocity.');
    velocity=plan.wheelVelocity_m_per_s;
    requireSynthesis(isnumeric(velocity) && isreal(velocity) && (isscalar(velocity) || ...
        (isvector(velocity) && numel(velocity)==numel(z))) && all(isfinite(velocity)), ...
        'Velocity must be finite scalar or one value per sample.');
    if isscalar(velocity), velocity=repmat(double(velocity),numel(z),1); else, velocity=double(velocity(:)); end
elseif isfield(plan,'wheelVelocity_m_per_s')
    requireSynthesis(isempty(plan.wheelVelocity_m_per_s),'Velocity has no mechanical consumer without a model.');
end
plan=struct('travel_m',z,'solverOptions',fsd.kinematics.solverSettings(plan.solverOptions), ...
    'wheelVelocity_m_per_s',velocity);
roles=fsd.model.actuationDesignPointRoles(); pointIds=seed.cornerId+"_"+roles;
points=zeros(numel(roles),3);
for j=1:numel(roles), points(j,:)=fsd.model.getActuationDesignPoint(actuation,pointIds(j)); end
[~,dependent]=max(abs(actuation.rocker.axis.direction_unit));
variables=cell(0,1); keys=strings(0,1); sources={strings(0,1);strings(0,1);strings(0,1)};
parameters=spec.definitionSI.parameters; constraints=spec.definitionSI.constraints;
for j=1:numel(parameters)
    p=parameters{j}.definitionSI;
    if ~any(p.type==["FREE","RANGE","FIXED"]) || p.binding=="NONE"
        requireSynthesis(~any(p.type==["FREE","RANGE"]),'Variables require explicit supported bindings.');
        continue;
    end
    if any(p.binding==["SPRING_RATE","SPRING_PRELOAD"])
        requireSynthesis(~isempty(mechanical) && p.scope.cornerId==seed.cornerId && p.type~="FREE", ...
            'Only FIXED/RANGE constraints on known mechanical parameters are supported.');
        sources{3}(end+1,1)=p.scope.id;
        continue;
    end
    component=find(["HARDPOINT_X","HARDPOINT_Y","HARDPOINT_Z"]==p.binding);
    requireSynthesis(isscalar(component) && p.scope.cornerId==seed.cornerId, 'Unsupported binding or corner.');
    row=find(pointIds==p.scope.id);
    if isempty(row)
        requireSynthesis(p.type=="FIXED" && ismember(p.scope.id,seed.hardpoints.ids), ...
            'Suspension geometry is immutable in actuation synthesis.');
        value=fsd.model.getPoint(seed,p.scope.id);
    else
        value=points(row,:);
    end
    if p.type=="FIXED"
        requireSynthesis(abs(value(component)-p.value)<=p.comparisonTolerance,'Seed contradicts FIXED coordinate.');
        continue;
    end
    requireSynthesis(~isempty(p.bounds) && all(isfinite(p.bounds)),'Geometric variables require closed finite bounds.');
    initial=value(component); bounds=p.bounds;
    requireSynthesis(initial>=bounds(1) && initial<=bounds(2),'Seed outside declared bounds.');
    if ~isempty(p.value), requireSynthesis(p.value==initial,'Declared nominal must equal seed coordinate.'); end
    requireSynthesis(row~=5 || component~=dependent || bounds(1)==bounds(2), ...
        'Canonical rocker axis point has only two independent coordinates.');
    key=p.scope.id+":"+p.binding; requireSynthesis(~ismember(key,keys),'Duplicate coordinate binding.');
    keys(end+1,1)=key; %#ok<AGROW>
    variables{end+1,1}=struct('id',p.id,'cornerId',seed.cornerId,'hardpointId',p.scope.id, ...
        'role',roles(row),'row',row,'column',component,'component',extractAfter(p.binding,'HARDPOINT_'), ...
        'initial_m',initial,'lower_m',bounds(1),'upper_m',bounds(2),'unit',"m",'parameter',p); %#ok<AGROW>
end
for j=1:numel(constraints)
    c=constraints{j}.definitionSI;
    requireSynthesis(c.scope.cornerId==seed.cornerId && ismember(c.scope.id,[pointIds;seed.hardpoints.ids]), ...
        'Constraint references a missing point or another corner.');
    if c.type=="HARDPOINT_FIXED" && c.strength=="HARD"
        point=nominal(c.scope.id); requireSynthesis(all(abs(point-c.position)<=c.comparisonTolerance),'Seed contradicts HARD FIXED point.');
    end
end
for j=1:numel(variables)
    v=variables{j}; if v.lower_m==v.upper_m, continue; end
    affected=v.column;
    if v.row==5 && actuation.rocker.axis.direction_unit(v.column)~=0, affected=[v.column,dependent]; end
    for k=1:numel(parameters)
        p=parameters{k}.definitionSI; column=find(["HARDPOINT_X","HARDPOINT_Y","HARDPOINT_Z"]==p.binding);
        if p.scope.id==v.hardpointId && p.type=="FIXED" && isscalar(column) && ismember(column,affected)
            requireSynthesis(false,'FIXED coordinates cannot change directly or through axis canonicalization.');
        end
    end
    for k=1:numel(variables)
        frozen=variables{k};
        requireSynthesis(~(frozen.hardpointId==v.hardpointId && frozen.lower_m==frozen.upper_m && ...
            ismember(frozen.column,affected)),'Frozen axis coordinates cannot change indirectly.');
    end
    for k=1:numel(constraints)
        c=constraints{k}.definitionSI;
        requireSynthesis(~(c.scope.id==v.hardpointId && c.type=="HARDPOINT_FIXED" && c.strength=="HARD"), ...
            'HARD FIXED point cannot be a moving variable.');
    end
end
targets=spec.definitionSI.targets.definitionSI.targets;
for j=1:numel(targets)
    q=targets{j}.definitionSI; family=0;
    if q.sourceType=="BUMP" && ismember(q.metricId,["CAMBER","TOE","BUMP_STEER","CASTER","KPI"]), family=1; end
    if q.sourceType=="ACTUATION" && ismember(q.metricId,["DAMPER_COMPRESSION","MOTION_RATIO","INSTALLATION_RATIO","ROCKER_ANGLE"]), family=2; end
    if q.sourceType=="MECHANICAL" && ismember(q.metricId,["DAMPER_COMPRESSION","MOTION_RATIO","INSTALLATION_RATIO", ...
            "SPRING_AXIAL_FORCE","SPRING_WHEEL_RESISTANCE","TANGENT_WHEEL_RATE"]), family=3; end
    if family==0 || q.scope.id~=seed.cornerId || ~isempty(q.requiredSourceIdentity)
        error('fsd:synthesis:UnsupportedTarget','Target %s is not reconstructible by corner actuation synthesis.',q.id);
    end
    if family==3 && isempty(mechanical), error('fsd:synthesis:MissingMechanicalModel','Target %s requires a compatible mechanical seed.',q.id); end
    sources{family}(end+1,1)=q.sourceId;
end
for j=1:3
    sources{j}=unique(sources{j},'stable');
    if isempty(sources{j}) && (j<3 || ~isempty(mechanical))
        labels=["BUMP","ACTUATION","MECHANICAL"]; sources{j}="SYNTH_"+labels(j)+"_"+seed.cornerId;
    end
end
allIds=vertcat(sources{:}); requireSynthesis(numel(unique(allIds))==numel(allIds),'Aliases cannot cross physical families.');
lower=cellfun(@(v)v.lower_m,variables); upper=cellfun(@(v)v.upper_m,variables); initial=cellfun(@(v)v.initial_m,variables);
requireSynthesis(all(isfinite(upper-lower)),'Variable spans must be representable.');
space=struct('schemaVersion',"0.15.0",'kind',"ActuationSynthesisDesignSpace",'seed',seed, ...
    'seedIdentity',fsd.model.geometryIdentity(seed),'seedActuation',actuation,'seedMechanical',mechanical, ...
    'specification',spec,'plan',plan,'sourceIds',{sources},'pointIds',pointIds,'seedPoints_m',points, ...
    'dependentAxisComponent',dependent,'variables',{variables},'lower_m',lower,'upper_m',upper, ...
    'initial_m',initial,'active',upper>lower);

    function point = nominal(id)
        r=find(pointIds==id);
        if isempty(r), point=fsd.model.getPoint(seed,id); else, point=points(r,:); end
    end
end
