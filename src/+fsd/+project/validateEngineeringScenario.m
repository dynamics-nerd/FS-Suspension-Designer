function valid = validateEngineeringScenario(scenario)
%VALIDATEENGINEERINGSCENARIO Reconstruct canonical intent, not its physical execution.
projectRequire(isequaln(scenario,scenarioCore(scenario.definition)), 'Scenario identity or definition mismatch.');
valid=true;
end
