function scenario = scenarioFind(project,id)
%SCENARIOFIND Resolve an explicit scenario ID in the current revision.
id=projectText(id); entries=project.definition.scenarios;
for j=1:numel(entries)
    if entries{j}.definition.id==id, scenario=entries{j}; return; end
end
error('fsd:project:MissingScenario','No scenario %s exists in project %s.',id,project.id);
end
