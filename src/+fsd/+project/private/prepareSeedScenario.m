function prepared = prepareSeedScenario(project,scenario)
%PREPARESEEDSCENARIO Input readiness only; nominal construction is an explicit action.
try
    prepared=prepareSeedScenarioCore(project,scenario);
catch cause
    allowed=["fsd:project:InvalidInput","fsd:construction:InvalidInput","fsd:kinematics:InvalidOptions"];
    if ~ismember(string(cause.identifier),allowed), rethrow(cause); end
    r=struct('scenarioId',scenario.definition.id,'engine',scenario.definition.engine,'scope',scenario.definition.scope, ...
        'status',"INVALID_INPUT",'missing',strings(0,1),'diagnostics',string(cause.identifier)+":"+string(cause.message), ...
        'limitations',"Invalid construction inputs; no nominal or sampled certification.");
    prepared=struct('schemaVersion',"0.16.0",'kind',"PreparedEngineeringScenario",'scenario',scenario, ...
        'resources',resourceCore(struct()),'space',[],'plan',scenario.definition.plan,'options',scenario.definition.options, ...
        'vehicle',[],'loadCase',[],'context',[],'readiness',r,'seedDefinition',[],'seedReferences',{{}});
end
end

function prepared = prepareSeedScenarioCore(project,scenario)
d=scenario.definition;
r=struct('scenarioId',d.id,'engine',d.engine,'scope',d.scope,'status',"READY", ...
    'missing',strings(0,1),'diagnostics',strings(0,1), ...
    'limitations',["READY is input completeness, not nominal validity or sampled feasibility."; ...
    "No continuous, CAD, structural, vehicle-performance or regulatory certification."]);
prepared=struct('schemaVersion',"0.16.0",'kind',"PreparedEngineeringScenario",'scenario',scenario, ...
    'resources',resourceCore(struct()),'space',[],'plan',d.plan,'options',d.options, ...
    'vehicle',[],'loadCase',[],'context',[],'readiness',r,'seedDefinition',[],'seedReferences',{{}});
if ~isfield(d.inputs,'definition')
    r.status="MISSING_DATA"; r.missing="INPUT:PARAMETRIC_DEFINITION"; prepared.readiness=r; return;
end
projectRequire(isequal(string(fieldnames(d.inputs)),"definition") && isempty(d.specification) && ...
    isempty(fieldnames(d.options)) && isempty(d.symmetryLinks) && isempty(d.conceptDependencies) && isempty(d.targetOrigins), ...
    'Parametric scenarios consume only an explicit definition and separate BUMP plan.');
definition=d.inputs.definition; fsd.construction.validateParametricSeedDefinition(definition);
corner=definition.definitionSI.cornerId; kind="CORNER"; if corner=="FRONT", kind="AXLE"; end
projectRequire(isequaln(d.scope,fsd.model.designScope(kind,corner)), 'Construction scope differs from its definition.');
inputs=seedConceptInputs(project.definition.concept,definition);
if ~ismember(inputs.architecture,["UNSELECTED","DOUBLE_WISHBONE"])
    r.status="UNSUPPORTED"; r.diagnostics="Concept architecture is not DOUBLE_WISHBONE.";
end
ready=fsd.construction.parametricSeedReadiness(definition,inputs.parameters);
r.missing=unique([inputs.missing;ready.missing],'stable'); r.diagnostics=[r.diagnostics;inputs.diagnostics;ready.diagnostics];
if ready.status=="UNSUPPORTED" || ready.status=="INVALID_INPUT", r.status=ready.status; end
if d.engine=="PARAMETRIC_BUMP"
    if ~isfield(d.plan,'travel_m'), r.missing(end+1,1)="PLAN:travel_m";
    else, prepared.plan=seedBumpPlan(d.plan); end
else
    projectRequire(isempty(fieldnames(d.plan)), 'Nominal construction accepts no BUMP plan.');
end
prepared.seedDefinition=definition; prepared.seedReferences=inputs.parameters;
if ~isempty(r.missing) && r.status=="READY", r.status="MISSING_DATA"; end
if r.status=="READY"
    contextScenario=scenario.identity; contextScenario.definition.inputs=struct('definition',definition.identity);
    contextScenario.definition.plan=prepared.plan;
    prepared.context=struct('engine',d.engine,'scenario',contextScenario,'references',{inputs.identities}, ...
        'architecture',inputs.architecture);
end
prepared.readiness=r;
end
