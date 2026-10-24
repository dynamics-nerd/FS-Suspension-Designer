function [project,tire]=registerTire(project,definition)
%REGISTERTIRE Append an immutable tire revision; never rewrite existing ones.
fsd.project.validateEngineeringProject(project); resources=project.definition.resources;
if ~isfield(resources,'tires'), resources.tires=cell(0,1); end
tire=fsd.tire.create(definition); same=resources.tires(cellfun(@(x)x.definition.id==tire.definition.id,resources.tires));
if ~isempty(same)
    [revision,index]=max(cellfun(@(x)x.definition.revision,same));
    d=tire.definition; d.revision=revision;
    if isequaln(fsd.tire.create(d),same{index}), tire=same{index}; return; end
    d.revision=revision+1; tire=fsd.tire.create(d);
else
    assert(tire.definition.revision==1,'fsd:project:InvalidInput','First tire revision must be 1.');
end
resources.tires{end+1,1}=tire;
project=fsd.project.reviseEngineeringProject(project,struct('resources',resources));
end
