function [project,actuation,mechanical] = configureActuationResources(project,cornerId,definition,lengthUnit,mechanicalDefinition,units)
%CONFIGUREACTUATIONRESOURCES Atomic native resource declaration; no solves.
% mechanicalDefinition=[] explicitly removes this corner's previous coilover.
fsd.project.validateEngineeringProject(project);
cornerId=string(cornerId); resources=project.definition.resources;
found=cellfun(@(g)g.cornerId==cornerId,resources.geometries);
assert(nnz(found)==1,'fsd:project:MissingGeometry','Select one registered suspension geometry.');
actuation=fsd.model.createActuationGeometry(resources.geometries{found},definition,lengthUnit);
mechanical=[];
if ~isempty(mechanicalDefinition)
    mechanical=fsd.model.createSpringDamperModel(actuation,mechanicalDefinition,units);
end
resources.actuations=replace(resources.actuations,actuation,cornerId);
resources.mechanicals=replace(resources.mechanicals,mechanical,cornerId);
project=fsd.project.reviseEngineeringProject(project,struct('resources',resources));
end

function entries=replace(entries,value,corner)
entries=entries(~cellfun(@(r)r.cornerId==corner,entries));
if ~isempty(value), entries{end+1,1}=value; end
end
