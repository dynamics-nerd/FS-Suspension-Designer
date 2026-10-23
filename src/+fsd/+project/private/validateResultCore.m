function valid = validateResultCore(result,context)
%VALIDATEENGINEERINGRESULT Reconstruct original configuration and native evidence.
% Native synthesis validators replay stored search records; no new physical solves.
try
    projectRequire(isstruct(result) && isscalar(result) && result.schemaVersion=="0.16.0" && ...
        result.kind=="EngineeringResult",'Invalid result header.'); plainProjectData(result);
    validateTimers(result.nativePayload);
    snapshot=result.projectAtExecution;
    projectRequire(isempty(snapshot.definition.results) && isempty(snapshot.definition.derivations), ...
        'Execution snapshot must not contain recursive result/derivation ledgers.');
    context.project(snapshot);
    scenario=scenarioFind(snapshot,result.scenarioAtExecution.definition.id);
    projectRequire(isequaln(scenario,result.scenarioAtExecution),'Scenario does not belong to original project snapshot.');
    p=context.prepare(snapshot,scenario);
    projectRequire(p.readiness.status=="READY", ...
        'Original scenario is not READY: '+strjoin([p.readiness.missing;p.readiness.diagnostics],'; '));
    projectRequire(isequaln(p,result.prepared),'Prepared context mismatch.');
    expectedId=struct('schemaVersion',"0.16.0",'id',result.id,'projectId',snapshot.id, ...
        'projectRevision',snapshot.definition.revision,'context',p.context);
    projectRequire(isequaln(result.identity,expectedId) && isequaln(result.projectIdentity,snapshot.identity) && ...
        result.projectId==snapshot.id && result.projectRevision==snapshot.definition.revision && ...
        result.engine==scenario.definition.engine,'Crossed revision, project, engine or identity.');
    projectRequire(~isempty(regexp(projectText(result.id),'^[A-Z][A-Z0-9_]*$','once')) && ...
        ismember(projectText(result.fsdVersion),["0.16.0","0.17.0","0.18.0","0.19.0","0.20.0","0.21.0"]),'Invalid result ID/software contract.');
    if ismember(result.engine,["PARAMETRIC_SEED","PARAMETRIC_BUMP"])
        projectRequire(ismember(result.fsdVersion,["0.17.0","0.18.0","0.19.0","0.20.0","0.21.0"]),'Construction requires v0.17 or its compatible consumer.');
    end
    if result.engine=="PACKAGING", projectRequire(ismember(result.fsdVersion,["0.19.0","0.20.0","0.21.0"]),'Packaging requires v0.19 or its compatible consumer.'); end
    if result.engine=="GLOBAL_STATIC", projectRequire(result.fsdVersion=="0.21.0",'Global project integration requires v0.21.'); end
    projectRequire(isnumeric(result.elapsedTime_s) && isreal(result.elapsedTime_s) && ...
        isscalar(result.elapsedTime_s) && isfinite(result.elapsedTime_s) && result.elapsedTime_s>=0 && ...
        isequaln(result.diagnostics,p.readiness.limitations),'Invalid execution timing/diagnostics.');
    assessment=context.payload(p,result.nativePayload);
    projectRequire(isequaln(workflowComparable(assessment),workflowComparable(result.assessment)),'Assessment mismatch.');
    fields=["schemaVersion","kind","id","projectId","projectRevision","projectIdentity","projectAtExecution", ...
        "scenarioAtExecution","prepared","engine","fsdVersion","nativePayload","assessment","elapsedTime_s","diagnostics","identity"];
    projectRequire(isequal(sort(string(fieldnames(result))),sort(fields(:))),'Unknown/missing result fields.');
catch cause
    exception=MException('fsd:project:InvalidEngineeringResult','Engineering result cannot be reconstructed from its original context.');
    throwAsCaller(addCause(exception,cause));
end
valid=true;
end

function validateTimers(value)
% Clock fields may differ on replay, but never contain invalid clock values.
if isstruct(value)
    names=string(fieldnames(value));
    for j=1:numel(value)
        for name=names'
            field=value(j).(name);
            if endsWith(lower(name),'elapsedtime_s')
                projectRequire(isnumeric(field) && isreal(field) && isscalar(field) && isfinite(field) && field>=0, ...
                    'Invalid informational elapsed-time field.');
            elseif ~ismember(name,["metadata","definitionSI"])
                validateTimers(field);
            end
        end
    end
elseif iscell(value)
    for j=1:numel(value), validateTimers(value{j}); end
end
end
