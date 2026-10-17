function definition = seedDefinition(project,scope)
%SEEDDEFINITION Retrieve a declared scenario, or an empty explicit DW family.
id="UI_BUILD_"+string(scope);
ss=project.definition.scenarios;
for j=1:numel(ss)
    if ss{j}.definition.id==id, definition=ss{j}.definition.inputs.definition; return; end
end
input=struct('id',"UI_SEED_"+string(scope),'cornerId',string(scope), ...
    'family',"INDEPENDENT_DOUBLE_WISHBONE");
definition=fsd.construction.createParametricSeedDefinition(input);
end
