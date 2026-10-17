function project = upsertScenario(project,scenario)
%UPSERTSCENARIO Preserve every other scenario and the historical ledger.
ss=project.definition.scenarios;
keep=~cellfun(@(s)s.definition.id==scenario.definition.id,ss);
project=fsd.project.reviseEngineeringProject(project,struct('scenarios',{{ss{keep},scenario}}));
end
