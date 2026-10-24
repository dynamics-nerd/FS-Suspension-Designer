function p=prepareTireScenario(project,scenario)
%PREPARETIRESCENARIO Exact requested revision, states and channel contract.
d=scenario.definition;
r=struct('scenarioId',d.id,'engine',d.engine,'scope',d.scope,'status',"READY", ...
    'missing',strings(0,1),'diagnostics',strings(0,1), ...
    'limitations',["Stationary reduced tire model; no experimental validation implied."; ...
    "DUGOFF_REDUCED_1 is not MathWorks Dugoff; Mz/transients/thermal effects unsupported."]);
p=struct('schemaVersion',"0.16.0",'kind',"PreparedEngineeringScenario",'scenario',scenario, ...
    'resources',resourceCore(struct()),'plan',d.plan,'options',d.options,'tire',[], ...
    'context',[],'readiness',r);
try
    projectRequire(d.scope.kind=="VEHICLE"&&isempty(d.specification)&&isempty(d.targetOrigins)&& ...
        isempty(d.conceptDependencies)&&isempty(d.symmetryLinks)&&isempty(fieldnames(d.options)), ...
        'Tire characterization requires project vehicle scope without targets/options.');
    projectRequire(all(ismember(string(fieldnames(d.inputs)),["tireId","tireRevision"]))&& ...
        all(ismember(string(fieldnames(d.plan)),["states","request"])),'Unknown tire study fields.');
    for n=["tireId","tireRevision"]
        if ~isfield(d.inputs,n), r.missing(end+1,1)="INPUT:"+n; end
    end
    for n=["states","request"]
        if ~isfield(d.plan,n), r.missing(end+1,1)="PLAN:"+n; end
    end
    if ~isempty(r.missing), r.status="MISSING_DATA"; p.readiness=r; return; end
    projectRequire(isstring(d.inputs.tireId)&&isscalar(d.inputs.tireId)&&isnumeric(d.inputs.tireRevision)&& ...
        isscalar(d.inputs.tireRevision)&&isfinite(d.inputs.tireRevision),'Exact tire reference required.');
    p.tire=fsd.project.findTire(project,d.inputs.tireId,d.inputs.tireRevision);
    if isempty(p.tire), r.status="MISSING_DATA"; r.missing="TIRE:REGISTER_REVISION"; p.readiness=r; return; end
    ready=fsd.tire.readiness(p.tire,d.plan.states,d.plan.request);
    r.status=ready.status; r.missing=ready.missing; r.diagnostics=ready.diagnostics;
    p.resources.tires={p.tire};
    % Complete execution identity stays immutable, including original v0.22 MAT.
    % compatibilityCore derives the separate physical reuse projection.
    p.context=struct('engine',d.engine,'scenario',scenario.identity,'tire',p.tire.identity);
catch cause
    if ~startsWith(string(cause.identifier),["fsd:project:","fsd:tire:"]), rethrow(cause); end
    r.status="INVALID_INPUT"; r.diagnostics=string(cause.identifier)+": "+string(cause.message);
end
p.readiness=r;
end
