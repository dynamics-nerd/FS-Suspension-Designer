function scenario=createPackagingScenario(id,cornerId,packagingId,plan,parent,selection,candidateIndex)
%CREATEPACKAGINGSCENARIO Explicit stored-source adapter; does not execute analysis.
if ~isempty(parent)
    if parent.kind=="PackagingSourceReference", fsd.project.validatePackagingSource(parent);
    else, parent=fsd.project.createPackagingSource(parent); end
end
inputs=struct('packagingId',string(packagingId),'selection',string(selection), ...
    'parent',parent,'candidateIndex',candidateIndex);
scenario=fsd.project.createEngineeringScenario(struct('id',string(id),'engine',"PACKAGING", ...
    'scope',fsd.model.designScope('CORNER',cornerId),'plan',plan,'inputs',inputs));
end
