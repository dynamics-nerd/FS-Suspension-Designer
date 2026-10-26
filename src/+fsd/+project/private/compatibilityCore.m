function report=compatibilityCore(result,project,dependencyReference,context)
%COMPATIBILITYCORE Canonical classification after operation-local proof gates.
report=struct('status',"INCOMPATIBLE",'executedRevision',result.projectRevision, ...
    'currentRevision',project.definition.revision,'diagnostics',strings(0,1));
if result.projectId~=project.id, report.diagnostics="Different project ID."; return; end
ids=strings(numel(project.definition.scenarios),1);
for j=1:numel(ids), ids(j)=project.definition.scenarios{j}.definition.id; end
id=result.scenarioAtExecution.definition.id;
if ~ismember(id,ids), report.diagnostics="Original scenario no longer exists."; return; end
p=context.prepare(project,scenarioFind(project,id));
if p.readiness.status~="READY"
    report.status="STALE"; report.diagnostics=[p.readiness.missing;p.readiness.diagnostics]; return;
end
currentContext=p.context; executedContext=result.prepared.context;
if result.engine=="TIRE_CHARACTERIZATION" && p.scenario.definition.engine=="TIRE_CHARACTERIZATION"
    currentContext=tireReuseContext(p); executedContext=tireReuseContext(result.prepared);
end
if ismember(result.engine,["ARB_KINEMATICS","ARB_MECHANICAL","ARB_SIZING"])&&p.scenario.definition.engine==result.engine
    currentContext=arbReuseContext(p); executedContext=arbReuseContext(result.prepared);
end
if ~isequaln(currentContext,executedContext)
    report.status="STALE"; report.diagnostics="Relevant model, concept dependency, target, plan, architecture or control changed."; return;
end
if ~dependencyReference && isequaln(result.projectIdentity,project.identity), report.status="CURRENT_EXECUTION";
else
    report.status="REUSABLE_DEPENDENCIES";
    report.diagnostics="Dependencies unchanged; evidence still belongs to its original execution revision, not a new run.";
    if dependencyReference
        report.diagnostics="Verified dependency projection; not a new execution or the original complete project snapshot.";
    end
end
end
function value=arbReuseContext(p)
scenario=p.scenario.identity; scenario.definition.inputs=rmfield(scenario.definition.inputs,'arbRevision');
scenario.definition.plan=p.plan; scenario.definition.options=p.options;
operation="MECHANICAL"; if p.scenario.definition.engine=="ARB_KINEMATICS", operation="GEOMETRY"; end
if p.scenario.definition.engine=="ARB_SIZING", operation="SIZING"; end
resources=struct('geometries',{{}},'actuations',{{}});
for k=1:numel(p.resources.geometries)
    g=p.resources.geometries{k}; resources.geometries{k,1}=struct('geometry',fsd.model.geometryIdentity(g),'frame',g.referenceFrame);
end
for k=1:numel(p.resources.actuations)
    a=p.resources.actuations{k}.identity;
    resources.actuations{k,1}=rmfield(a,{'rockerDamperPointStatic_m','damperChassisPoint_m'});
end
value=struct('scenario',scenario,'bar',fsd.model.antiRollBarDependencies(p.bar,operation), ...
    'resources',resources,'driverOptions',p.driverOptions);
if isfield(p.plan,'packaging')
    components=p.plan.packaging.definition.components; consumesSupports=false;
    for k=1:numel(components)
        c=components{k}; consumesSupports=consumesSupports||any(ismember([c.firstPoint,c.secondPoint],["ARB_SUPPORT_LEFT","ARB_SUPPORT_RIGHT"]));
    end
    if consumesSupports
        value.packagingSupports=p.bar.definition.parameters.supports_m;
        if isfield(p.bar.definition.provenance,'supports_m'), value.packagingSupportSource=p.bar.definition.provenance.supports_m; end
    end
end
end
function value=tireReuseContext(p)
% Keep prepared.context byte-for-byte reconstructible for original v0.22 MAT.
% Exact worker/result validation still uses the complete prepared snapshot.
scenario=p.scenario.identity;
scenario.definition.inputs=rmfield(scenario.definition.inputs,'tireRevision');
scenario.definition.plan=struct();
value=struct('scenario',scenario, ...
    'consumed',fsd.tire.evaluationDependencies(p.tire,p.plan.states,p.plan.request));
end
