function evidence = bumpEvidence(result,project,compatibility)
%BUMPEVIDENCE Present canonical compatibility, never infer it from revisions.
% A supplied report comes from the Controller's canonical project API cache.
if nargin<3, compatibility=fsd.project.resultCompatibility(result,project); end
status=string(compatibility.status);
applicable=ismember(status,["CURRENT_EXECUTION","REUSABLE_DEPENDENCIES"]);
stored=result.prepared.resources.geometries{1};
corner=string(stored.cornerId); registered="ABSENT";
for j=1:numel(project.definition.resources.geometries)
    g=project.definition.resources.geometries{j};
    if g.cornerId==corner, registered=corner+" / "+g.referenceFrame.id; break; end
end
source=string(result.scenarioAtExecution.definition.id);
summary="["+status+"] "+result.id+" / "+source+" / "+corner+" | execution rev "+result.projectRevision;
if applicable, policy="STORED execution; dependencies applicable. Original convergence is not current validity.";
else, policy="HISTORICAL ONLY — NOT current geometry evidence. CONVERGED does not mean CURRENT."; end
detail=[summary;policy; ...
    "Stored geometry: "+corner+" / "+stored.referenceFrame.id+"; project "+result.projectId+" rev "+result.projectRevision; ...
    "Current registry: "+registered+"; project "+project.id+" rev "+project.definition.revision];
evidence=struct('status',status,'applicable',applicable,'summary',summary,'detail',detail, ...
    'resultId',result.id,'sourceId',source,'executedRevision',result.projectRevision, ...
    'currentRevision',project.definition.revision,'cornerId',corner);
end
