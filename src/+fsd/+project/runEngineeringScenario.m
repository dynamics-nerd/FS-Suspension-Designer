function [result,attachedProject] = runEngineeringScenario(project,scenarioId,resultId)
%RUNENGINEERINGSCENARIO Explicit delegation; no new solver or search algorithm.
% Optional second output appends the new fully validated result to the same
% immutable, fully validated input ledger. Configuration identity excludes the
% ledger; no second external trust boundary or skip-validation flag is needed.
context=validationContext(); context.project(project); resultId=projectText(resultId);
projectRequire(~isempty(regexp(resultId,'^[A-Z][A-Z0-9_]*$','once')),'Canonical result ID required.');
if nargout>1
    projectRequire(~any(cellfun(@(r)string(r.id)==resultId,project.definition.results)), ...
        'Duplicate result IDs.');
end
scenario=scenarioFind(project,scenarioId); prepared=context.prepare(project,scenario);
projectRequire(prepared.readiness.status=="READY", ...
    'Scenario is not READY: '+strjoin([prepared.readiness.missing;prepared.readiness.diagnostics],'; '));
timer=tic; [payload,assessment]=executeScenarioCore(prepared); elapsed=toc(timer);
% Retain the complete ORIGINAL configuration, never the recursive result ledger.
d=project.definition; d.results={}; d.derivations={}; snapshot=projectCore(d,context);
result=struct('schemaVersion',"0.16.0",'kind',"EngineeringResult",'id',resultId, ...
    'projectId',project.id,'projectRevision',project.definition.revision, ...
    'projectIdentity',project.identity,'projectAtExecution',snapshot,'scenarioAtExecution',scenario, ...
    'prepared',prepared,'engine',scenario.definition.engine,'fsdVersion',fsd.version(), ...
    'nativePayload',payload,'assessment',assessment,'elapsedTime_s',elapsed, ...
    'diagnostics',prepared.readiness.limitations, ...
    'identity',struct('schemaVersion',"0.16.0",'id',resultId,'projectId',project.id, ...
        'projectRevision',project.definition.revision,'context',prepared.context));
context.result(result);
if nargout>1
    records=[project.definition.results;{result}];
    [~,order]=sort(cellfun(@(r)string(r.id),records));
    attachedProject=project; attachedProject.definition.results=records(order);
end
end
