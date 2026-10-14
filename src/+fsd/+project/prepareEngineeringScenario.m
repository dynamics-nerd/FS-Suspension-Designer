function prepared = prepareEngineeringScenario(project,scenarioId)
%PREPAREENGINEERINGSCENARIO Native factories only: no sweeps, loads or searches.
validateProjectConfiguration(project);
scenario=scenarioFind(project,scenarioId);
prepared=prepareScenarioCore(project,scenario);
end
