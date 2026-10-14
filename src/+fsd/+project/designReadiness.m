function reports = designReadiness(project,scenarioId)
%DESIGNREADINESS Actionable input diagnostics; READY is not convergence evidence.
validateProjectConfiguration(project);
if nargin>1
    prepared=prepareScenarioCore(project,scenarioFind(project,scenarioId)); reports=prepared.readiness; return;
end
scenarios=project.definition.scenarios;
if isempty(scenarios)
    engines=["STATIC_GEOMETRY","BUMP","ROLL","RACK","ACTUATION","MECHANICAL", ...
        "TARGET_EVALUATION","CORNER_SYNTHESIS","AXLE_SYNTHESIS","STEERING_SYNTHESIS","ACTUATION_SYNTHESIS","STATIC_LOADS"];
    scenarios=cell(numel(engines),1);
    for j=1:numel(engines)
        scope=fsd.model.designScope('CORNER','FL');
        if ismember(engines(j),["ROLL","RACK","AXLE_SYNTHESIS","STEERING_SYNTHESIS"]), scope=fsd.model.designScope('AXLE','FRONT'); end
        if ismember(engines(j),["STATIC_LOADS","TARGET_EVALUATION"]), scope=fsd.model.designScope('VEHICLE','VEHICLE'); end
        scenarios{j}=scenarioCore(struct('id',"CAPABILITY_"+engines(j),'engine',engines(j),'scope',scope));
    end
end
reports=cell(numel(scenarios),1);
for j=1:numel(scenarios), p=prepareScenarioCore(project,scenarios{j}); reports{j}=p.readiness; end
end
