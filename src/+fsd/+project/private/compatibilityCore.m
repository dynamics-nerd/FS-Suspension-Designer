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
function value=tireReuseContext(p)
% Keep prepared.context byte-for-byte reconstructible for original v0.22 MAT.
% Exact worker/result validation still uses the complete prepared snapshot.
scenario=p.scenario.identity;
scenario.definition.inputs=rmfield(scenario.definition.inputs,'tireRevision');
scenario.definition.plan=struct();
value=struct('scenario',scenario, ...
    'consumed',fsd.tire.evaluationDependencies(p.tire,p.plan.states,p.plan.request));
end
