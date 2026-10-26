function [project,bar]=registerAntiRollBar(project,definition)
%REGISTERANTIROLLBAR Append immutable canonical revisions within this project.
fsd.project.validateEngineeringProject(project); resources=project.definition.resources;
if ~isfield(resources,'antiRollBars'), resources.antiRollBars=cell(0,1); end
bar=fsd.model.createAntiRollBar(definition); same=resources.antiRollBars(cellfun(@(b)b.definition.id==bar.definition.id,resources.antiRollBars));
if ~isempty(same)
    [revision,index]=max(cellfun(@(b)b.definition.revision,same)); d=bar.definition; d.revision=revision;
    if isequaln(fsd.model.createAntiRollBar(d),same{index}), bar=same{index}; return; end
    d.revision=revision+1; bar=fsd.model.createAntiRollBar(d);
else
    assert(bar.definition.revision==1,'fsd:project:InvalidInput','First ARB revision must be one.');
end
resources.antiRollBars{end+1,1}=bar;
project=fsd.project.reviseEngineeringProject(project,struct('resources',resources));
end
