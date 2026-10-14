function valid = validateProjectConfiguration(project)
%VALIDATEPROJECTCONFIGURATION Readiness checks inputs, not the historical ledger.
% Full ledger/native replay remains in validateEngineeringProject explicitly.
plainProjectData(project); d=project.definition; d.results={}; d.derivations={};
expected=projectCore(d); configuration=project;
configuration.definition.results=cell(0,1); configuration.definition.derivations=cell(0,1);
projectRequire(isequaln(configuration,expected),'Project configuration identity or definition mismatch.');
valid=true;
end
