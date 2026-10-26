function prepared = prepareScenarioCore(project,scenario,validation)
%PREPARESCENARIOCORE Dependency selection and native structural adapters only.
if nargin<3, validation=validationContext(); end
d=scenario.definition; engine=d.engine; scope=d.scope; registry=project.definition.resources;
if ismember(engine,["ARB_KINEMATICS","ARB_MECHANICAL","ARB_SIZING"])
    prepared=prepareArbScenario(project,scenario); return;
end
if engine=="TIRE_CHARACTERIZATION"
    prepared=prepareTireScenario(project,scenario); return;
end
if engine=="GLOBAL_STATIC"
    prepared=prepareGlobalScenario(project,scenario,validation); return;
end
if engine=="PACKAGING"
    prepared=preparePackagingScenario(project,scenario,validation); return;
end
if ismember(engine,["PARAMETRIC_SEED","PARAMETRIC_BUMP"])
    prepared=prepareSeedScenario(project,scenario); return;
end
supported=["STATIC_GEOMETRY","BUMP","ROLL","RACK","ACTUATION","MECHANICAL","TARGET_EVALUATION", ...
    "STATIC_LOADS","CORNER_SYNTHESIS","AXLE_SYNTHESIS","STEERING_SYNTHESIS","ACTUATION_SYNTHESIS"];
r=struct('scenarioId',d.id,'engine',engine,'scope',scope,'status',"READY", ...
    'missing',strings(0,1),'diagnostics',strings(0,1), ...
    'limitations',["Structural readiness does not guarantee physical convergence."; ...
    "No vehicle-performance, dynamic tire, CAD, structural or regulatory certification model is connected."]);
prepared=struct('schemaVersion',"0.16.0",'kind',"PreparedEngineeringScenario", ...
    'scenario',scenario,'resources',resourceCore(struct()),'space',[],'plan',d.plan, ...
    'options',d.options,'vehicle',[],'loadCase',[],'context',[],'readiness',r);
if ~ismember(engine,supported)
    r.status="UNSUPPORTED"; r.diagnostics="No project adapter for engine "+engine+"; native APIs may remain available.";
    prepared.readiness=r; return;
end
cornerEngines=["STATIC_GEOMETRY","BUMP","ACTUATION","MECHANICAL","CORNER_SYNTHESIS","ACTUATION_SYNTHESIS"];
axleEngines=["ROLL","RACK","AXLE_SYNTHESIS","STEERING_SYNTHESIS"];
if (ismember(engine,cornerEngines) && scope.kind~="CORNER") || ...
        (ismember(engine,axleEngines) && scope.kind~="AXLE") || ...
        (engine=="STATIC_LOADS" && scope.kind~="VEHICLE")
    r.status="INVALID_INPUT"; r.diagnostics="Engine and requested scope are incompatible."; prepared.readiness=r; return;
end
ids=strings(0,1);
if ismember(engine,cornerEngines), ids=scope.id; end
if ismember(engine,axleEngines)
    ids=["FL";"FR"]; if scope.id=="REAR", ids=["RL";"RR"]; end
end
if ismember(engine,["RACK","STEERING_SYNTHESIS"]) && scope.id~="FRONT"
    r.status="UNSUPPORTED"; r.diagnostics="Native rack-and-pinion supports FRONT only."; prepared.readiness=r; return;
end
for id=ids'
    g=resourceFind(registry,'geometries',id);
    if isempty(g), r.missing(end+1,1)="GEOMETRY:"+id;
    else
        prepared.resources.geometries{end+1,1}=g;
        if isfield(registry,'seedBindings')
            for k=1:numel(registry.seedBindings)
                binding=registry.seedBindings{k}; corners=cellfun(@(a)a.cornerId,binding.construction.geometries);
                if ~ismember(id,corners), continue; end
                [current,diagnostic]=seedBindingCurrent(project,binding);
                if ~current
                    r.status="BLOCKED_BY_DEPENDENCY"; r.missing(end+1,1)=diagnostic;
                end
                if ~isfield(prepared.resources,'seedBindings'), prepared.resources.seedBindings={}; end
                existing=prepared.resources.seedBindings;
                if ~any(cellfun(@(b)b.scenarioId==binding.scenarioId,existing))
                    prepared.resources.seedBindings{end+1,1}=binding;
                end
            end
        end
    end
    axleName="front"; if startsWith(id,'R'), axleName="rear"; end
    architecture=project.definition.concept.definitionSI.architectures.(axleName+"Suspension");
    if ~ismember(architecture,["UNSELECTED","DOUBLE_WISHBONE"])
        r.status="UNSUPPORTED"; r.diagnostics(end+1,1)="Chosen suspension architecture "+architecture+" has no native adapter.";
    end
end
if ismember(engine,["RACK","STEERING_SYNTHESIS"])
    s=resourceFind(registry,'steerings',"FRONT");
    if isempty(s), r.missing(end+1,1)="STEERING:FRONT"; else, prepared.resources.steerings={s}; end
end
if ismember(engine,["ACTUATION","MECHANICAL","ACTUATION_SYNTHESIS"])
    a=resourceFind(registry,'actuations',scope.id);
    if isempty(a), r.missing(end+1,1)="ACTUATION:"+scope.id; else, prepared.resources.actuations={a}; end
    m=resourceFind(registry,'mechanicals',scope.id);
    if ~isempty(m) && engine~="ACTUATION", prepared.resources.mechanicals={m}; end
    axis="front"; if startsWith(scope.id,'R'), axis="rear"; end
    choice=project.definition.concept.definitionSI.architectures.(axis+"Actuation");
    if ~isempty(a) && ~ismember(choice,["UNSELECTED",a.actuationType])
        r.status="UNSUPPORTED"; r.diagnostics(end+1,1)="Chosen actuation architecture does not match the explicit native resource.";
    end
    if engine=="MECHANICAL" && isempty(m), r.missing(end+1,1)="MECHANICAL:"+scope.id; end
end
synthesis=endsWith(engine,'SYNTHESIS');
if synthesis || engine=="TARGET_EVALUATION"
    if isempty(d.specification), r.missing(end+1,1)="DESIGN_SPECIFICATION"; end
end
if synthesis && ~isempty(d.specification)
    declaration=fsd.model.designVariableSpace(d.specification,false);
    for id=declaration.missingBoundsOrBindings'
        r.missing(end+1,1)="DESIGN_VARIABLE:"+id+":BOUNDS_OR_BINDING";
    end
end
if ~isempty(d.specification)
    ts=d.specification.definitionSI.targets.definitionSI.targets;
    for j=1:numel(ts)
        q=ts{j}.definitionSI;
        for k=1:j-1
            previous=ts{k}.definitionSI;
            if q.sourceId==previous.sourceId && q.sourceType~=previous.sourceType
                r.status="INVALID_INPUT";
                r.diagnostics(end+1,1)="SOURCE_ALIAS_CROSSES_FAMILIES:"+q.sourceId;
                prepared.readiness=r; return;
            end
        end
    end
    declared=cellfun(@(o)o.targetId,d.targetOrigins,'UniformOutput',false);
    for j=1:numel(ts)
        if ~any(cellfun(@(id)id==ts{j}.definitionSI.id,declared))
            r.diagnostics(end+1,1)="PENDING_JUSTIFICATION:TARGET:"+ts{j}.definitionSI.id;
        end
    end
end
requirements=strings(0,1);
switch engine
    case {"BUMP","ACTUATION","MECHANICAL","CORNER_SYNTHESIS","ACTUATION_SYNTHESIS"}, requirements="travel_m";
    case "ROLL", requirements=["angles_rad";"axleHeave_m"];
    case "RACK", requirements=["travel_m";"wheelTravel_m"];
    case "AXLE_SYNTHESIS", requirements=["leftBump";"rightBump"];
    case "STEERING_SYNTHESIS", requirements=["leftBump";"rightBump";"rack";"referenceRackTravel_m"];
end
if engine=="MECHANICAL" || (engine=="ACTUATION_SYNTHESIS" && ~isempty(prepared.resources.mechanicals))
    requirements(end+1,1)="wheelVelocity_m_per_s";
end
for name=requirements'
    if ~isfield(d.plan,name), r.missing(end+1,1)="PLAN:"+name; end
end
if engine=="TARGET_EVALUATION" && ~isfield(d.inputs,'candidate'), r.missing(end+1,1)="INPUT:CANDIDATE_WITH_VALIDATED_SOURCES"; end
dependencyValues=cell(numel(d.conceptDependencies),1);
for j=1:numel(d.conceptDependencies)
    id=d.conceptDependencies(j); [value,status]=conceptScalar(project.definition.concept,id);
    if isempty(value)
        r.missing(end+1,1)="CONCEPT:"+id;
        r.diagnostics(end+1,1)="CONCEPT:"+id+":"+status;
    else
        ps=project.definition.concept.definitionSI.parameters;
        index=cellfun(@(p)p.id==id,ps); dependencyValues{j}=ps{index}.identity;
    end
end
if r.status=="UNSUPPORTED", prepared.readiness=r; return; end
try
    if engine~="TARGET_EVALUATION"
        projectRequire(isempty(fieldnames(d.inputs)),'This adapter consumes no separate inputs payload.');
    end
    if ~ismember(engine,["AXLE_SYNTHESIS","STEERING_SYNTHESIS"])
        projectRequire(isempty(d.symmetryLinks),'Symmetry links require native axle/steering synthesis.');
    end
    if engine=="STATIC_LOADS"
        projectRequire(isempty(fieldnames(d.options)) && isempty(d.specification), ...
            'STATIC_LOADS uses explicit concept physical options in plan and no target specification.');
        c=conceptPreparation(project.definition.concept,d.plan);
        prepared.vehicle=c.model; prepared.loadCase=c.loadCase; prepared.plan=c.options;
        r.missing=[r.missing;c.missing]; r.diagnostics=[r.diagnostics;c.diagnostics];
        if c.status=="INVALID_INPUT", r.status=c.status; end
        % The project adapter promises at least axle loads. No unknown CG is inferred.
        if ~isempty(c.model) && ~isfinite(c.model.cg_m(1)), r.missing(end+1,1)="CONCEPT:CG_X_OR_LONGITUDINAL_WEIGHT_FRACTION"; end
    end
    if ~isempty(r.missing)
        if ~ismember(r.status,["INVALID_INPUT","BLOCKED_BY_DEPENDENCY"]), r.status="MISSING_DATA"; end
        prepared.readiness=r; return;
    end
    g=[]; if ~isempty(ids), g=resourceFind(prepared.resources,'geometries',ids(1)); end
    left=[]; right=[];
    if numel(ids)==2
        left=resourceFind(prepared.resources,'geometries',ids(1)); right=resourceFind(prepared.resources,'geometries',ids(2));
        fsd.model.createAxleGeometry(left,right);
        projectRequire(isequaln(left.referenceFrame,right.referenceFrame),'Axle corners must share the complete vehicle frame.');
    end
    switch engine
        case "CORNER_SYNTHESIS"
            prepared.space=fsd.synthesis.createDesignSpace(g,d.specification,d.plan);
        case "AXLE_SYNTHESIS"
            prepared.space=fsd.synthesis.createAxleDesignSpace(left,right,d.specification,d.plan,d.symmetryLinks);
        case "STEERING_SYNTHESIS"
            prepared.space=fsd.synthesis.createSteeringDesignSpace(left,right,s,d.specification,d.plan,d.symmetryLinks);
        case "ACTUATION_SYNTHESIS"
            prepared.space=fsd.synthesis.createActuationDesignSpace(g,a,m,d.specification,d.plan);
        case {"BUMP","ACTUATION","MECHANICAL"}
            allowed=["travel_m","solverOptions"]; if engine=="MECHANICAL", allowed(end+1)="wheelVelocity_m_per_s"; end
            projectRequire(all(ismember(string(fieldnames(d.plan)),allowed)) && isempty(fieldnames(d.options)), ...
                'Analysis controls belong in the explicit physical plan.');
            prepared.plan.travel_m=workflowGrid(d.plan.travel_m);
            opts=struct(); if isfield(d.plan,'solverOptions'), opts=d.plan.solverOptions; end
            prepared.plan.solverOptions=fsd.kinematics.solverSettings(opts);
            if engine=="MECHANICAL"
                v=d.plan.wheelVelocity_m_per_s; projectRequire(isnumeric(v) && isreal(v) && ...
                    (isscalar(v) || (isvector(v) && numel(v)==numel(prepared.plan.travel_m))) && all(isfinite(v)), ...
                    'Explicit velocity must be finite scalar or one per travel sample.');
                if isscalar(v), v=repmat(v,numel(prepared.plan.travel_m),1); end
                prepared.plan.wheelVelocity_m_per_s=double(v(:));
            end
        case "ROLL"
            projectRequire(all(ismember(string(fieldnames(d.plan)),["angles_rad","axleHeave_m","solverOptions"])) && ...
                isempty(fieldnames(d.options)), 'Invalid ROLL plan fields.');
            prepared.plan.angles_rad=workflowGrid(d.plan.angles_rad);
            projectRequire(all(abs(prepared.plan.angles_rad)<pi/2) && isnumeric(d.plan.axleHeave_m) && ...
                isscalar(d.plan.axleHeave_m) && isreal(d.plan.axleHeave_m) && isfinite(d.plan.axleHeave_m), 'Invalid native ROLL angle/heave.');
            opts=struct(); if isfield(d.plan,'solverOptions'), opts=d.plan.solverOptions; end
            prepared.plan.solverOptions=fsd.kinematics.rollSolverSettings(opts);
            fsd.analysis.geometricWheelContact(left); fsd.analysis.geometricWheelContact(right);
        case "RACK"
            projectRequire(all(ismember(string(fieldnames(d.plan)),["travel_m","wheelTravel_m","solverOptions"])) && ...
                isempty(fieldnames(d.options)), 'Invalid RACK plan fields.');
            prepared.plan.travel_m=workflowGrid(d.plan.travel_m); z=d.plan.wheelTravel_m;
            projectRequire(isnumeric(z) && isreal(z) && isvector(z) && ismember(numel(z),[1,2]) && all(isfinite(z)), ...
                'Explicit fixed RACK wheel travel required.');
            if isscalar(z), z=[z,z]; end
            prepared.plan.wheelTravel_m=double(reshape(z,1,2));
            opts=struct(); if isfield(d.plan,'solverOptions'), opts=d.plan.solverOptions; end
            prepared.plan.solverOptions=fsd.kinematics.solverSettings(opts);
        case "TARGET_EVALUATION"
            projectRequire(isempty(fieldnames(d.plan)) && isempty(fieldnames(d.options)) && ...
                isequal(string(fieldnames(d.inputs)),"candidate"),'Evaluation requires only explicit precomputed candidate.');
            fsd.analysis.validateDesignCandidate(d.inputs.candidate);
            requests=fsd.project.specificationSources(d.specification);
            sources=d.inputs.candidate.definitionSI.sources;
            for j=1:numel(requests)
                q=requests{j}; matches=cellfun(@(s)s.id==q.sourceId && s.type==q.sourceType,sources);
                if ~any(matches)
                    r.missing(end+1,1)="SOURCE:"+q.sourceId+":"+q.sourceType;
                elseif ~isempty(q.requiredSourceIdentity)
                    refs=d.inputs.candidate.identity.definitionSI.sources;
                    if ~isequaln(q.requiredSourceIdentity,refs{matches})
                        r.missing(end+1,1)="SOURCE_IDENTITY:"+q.sourceId;
                    end
                end
                if any(matches) && ~requestMatches(q,sources{matches})
                    r.missing(end+1,1)="SOURCE_SCOPE_OR_CONDITION:"+q.targetId+":"+q.sourceId;
                end
            end
            if ~isempty(r.missing)
                r.status="BLOCKED_BY_DEPENDENCY"; prepared.readiness=r; return;
            end
        case "STATIC_GEOMETRY"
            projectRequire(isempty(fieldnames(d.plan)) && isempty(fieldnames(d.options)), 'Static geometry accepts no solver controls.');
    end
    if synthesis
        prepared.plan=prepared.space.plan;
        prepared.options=fsd.synthesis.searchSettings(d.options,numel(prepared.space.initial_m));
    end
    if ~isempty(d.specification) && ~synthesis && engine~="TARGET_EVALUATION"
        requests=fsd.project.specificationSources(d.specification);
        families=engine; if engine=="MECHANICAL", families=["BUMP","ACTUATION","MECHANICAL"]; end
        if engine=="ACTUATION", families=["BUMP","ACTUATION"]; end
        for j=1:numel(requests)
            q=requests{j};
            if ~ismember(q.sourceType,families)
                error('fsd:project:UnsupportedSource','Target %s needs unavailable source %s.',q.targetId,q.sourceType);
            end
            scopeIds=scope.id; if numel(ids)==2, scopeIds=[scopeIds;ids]; end %#ok<AGROW>
            projectRequire(ismember(q.scope.id,scopeIds),'Target source scope differs from the scenario.');
            if (engine=="RACK" && ~isequaln(q.conditions.wheelTravel_m,prepared.plan.wheelTravel_m)) || ...
                    (engine=="ROLL" && q.conditions.axleHeave_m~=prepared.plan.axleHeave_m)
                r.status="BLOCKED_BY_DEPENDENCY";
                r.missing(end+1,1)="PLAN_CONDITION:"+q.targetId;
            end
        end
    end
catch cause
    id=string(cause.identifier);
    expected=["fsd:project:InvalidInput","fsd:synthesis:InvalidInput","fsd:synthesis:UnsupportedTarget", ...
        "fsd:synthesis:MissingAnalysisPlan","fsd:synthesis:MissingMechanicalModel", ...
        "fsd:kinematics:InvalidOptions","fsd:kinematics:InvalidRollOptions", ...
        "fsd:model:InvalidAxleGeometry","fsd:model:InvalidAxleCorners","fsd:model:InvalidDesignDefinition", ...
        "fsd:model:IncompleteDesignSpace","fsd:project:UnsupportedSource", ...
        "fsd:analysis:InvalidDesignCandidate"];
    if ~ismember(id,expected), rethrow(cause); end
    r.status="INVALID_INPUT";
    if ismember(id,["fsd:synthesis:UnsupportedTarget","fsd:project:UnsupportedSource"]), r.status="UNSUPPORTED"; end
    if ismember(id,["fsd:synthesis:MissingAnalysisPlan","fsd:synthesis:MissingMechanicalModel"]), r.status="BLOCKED_BY_DEPENDENCY"; end
    r.diagnostics(end+1,1)=id+": "+string(cause.message); prepared.readiness=r; return;
end
if r.status~="READY", prepared.readiness=r; return; end
contextScenario=scenario.identity; contextScenario.definition.plan=prepared.plan; contextScenario.definition.options=prepared.options;
context=struct('engine',engine,'scenario',contextScenario,'resources',resourceIdentities(prepared.resources), ...
    'conceptDependencies',{dependencyValues},'architectures',struct(),'vehicle',[],'loadCase',[]);
for id=ids'
    axis="front"; if startsWith(id,'R'), axis="rear"; end
    context.architectures.(axis+"Suspension")=project.definition.concept.definitionSI.architectures.(axis+"Suspension");
    if ismember(engine,["ACTUATION","MECHANICAL","ACTUATION_SYNTHESIS"])
        context.architectures.(axis+"Actuation")=project.definition.concept.definitionSI.architectures.(axis+"Actuation");
    end
end
if engine=="STATIC_LOADS"
    context.vehicle=prepared.vehicle.identity; context.loadCase=prepared.loadCase.identity;
    context.conceptDependencies=project.definition.concept.identity;
end
prepared.context=context; prepared.readiness=r;
end

function matches = requestMatches(request,source)
% Match physical ownership and fixed coordinates, not metric values or quality.
scope=request.scope; model=source.model; matches=true;
switch source.type
    case {"BUMP","ACTUATION","MECHANICAL"}, matches=scope.id==model.cornerId;
    case "RACK"
        matches=ismember(scope.id,["FRONT","FL","FR"]) && ...
            isequaln(request.conditions.wheelTravel_m,source.sweep.requestedWheelTravel_m);
    case "ROLL"
        matches=ismember(scope.id,[model.axleId,model.leftGeometry.cornerId,model.rightGeometry.cornerId]) && ...
            request.conditions.axleHeave_m==source.sweep.requestedAxleHeave_m;
end
end

function values = workflowGrid(values)
projectRequire(isnumeric(values) && isreal(values) && isvector(values) && ~isempty(values) && all(isfinite(values)), ...
    'Finite nonempty prescribed grid required.'); values=double(values(:));
projectRequire(isscalar(values) || all(diff(values)>0) || all(diff(values)<0),'Grid must be strictly ordered.');
end

function identities = resourceIdentities(resources)
identities=resources;
for name=string(fieldnames(resources))'
    entries=resources.(name);
    for j=1:numel(entries)
        r=entries{j};
        if name=="geometries"
            entries{j}=struct('geometry',fsd.model.geometryIdentity(r),'referenceFrame',r.referenceFrame);
        else
            entries{j}=r.identity;
        end
    end
    identities.(name)=entries;
end
end
