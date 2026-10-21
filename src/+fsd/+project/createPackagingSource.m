function source=createPackagingSource(result)
%CREATEPACKAGINGSOURCE Bounded dependency projection, NOT another execution.
% The original EngineeringResult remains untouched in the project ledger.
fsd.project.validateEngineeringResult(result);
projectRequire(ismember(result.engine,["BUMP","CORNER_SYNTHESIS","AXLE_SYNTHESIS"]), ...
    'Packaging source requires native BUMP/corner/axle evidence.');
d=result.projectAtExecution.definition;
% Packaging declarations/results are not dependencies of these native engines.
% Retain every native scenario (including seed bindings), concept and resource.
d.scenarios=d.scenarios(~cellfun(@(s)s.definition.engine=="PACKAGING",d.scenarios));
if isfield(d.resources,'packaging'), d.resources=rmfield(d.resources,'packaging'); end
snapshot=projectCore(d); p=prepareScenarioCore(snapshot,result.scenarioAtExecution);
projectRequire(isequaln(p,result.prepared),'Dependency projection changed the native preparation/context.');
source=struct('schemaVersion',"0.19.0",'kind',"PackagingSourceReference",'id',result.id, ...
    'projectId',result.projectId,'projectRevision',result.projectRevision,'engine',result.engine, ...
    'fsdVersion',result.fsdVersion,'sourceIdentity',result.identity,'dependencySnapshot',snapshot, ...
    'scenarioAtExecution',result.scenarioAtExecution,'prepared',p,'nativePayload',result.nativePayload, ...
    'assessment',result.assessment,'elapsedTime_s',result.elapsedTime_s);
fsd.project.validatePackagingSource(source);
end
