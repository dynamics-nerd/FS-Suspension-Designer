function [project,bump]=packagingHistoryFixture(count)
%PACKAGINGHISTORYFIXTURE Native synthetic three-state path, no stored simulation.
[definition,g]=packagingMotionFixture(.08);
scenario=fsd.project.createEngineeringScenario(struct('id',"BUMP_SOURCE",'engine',"BUMP", ...
    'scope',fsd.model.designScope('CORNER','FL'),'plan',struct('travel_m',[0;.04;.08])));
concept=fsd.project.createVehicleConcept(struct('id',"HISTORY_TEST"));
project=fsd.project.createEngineeringProject(struct('concept',concept, ...
    'resources',struct('geometries',{{g}},'packaging',{{definition}}),'scenarios',{{scenario}}));
bump=fsd.project.runEngineeringScenario(project,"BUMP_SOURCE","BUMP_EVIDENCE");
project=fsd.project.attachEngineeringResult(project,bump);
s=fsd.project.createPackagingScenario('PACK','FL','SOFTWARE_CASE', ...
    struct('mode',"BUMP",'requested_m',[0;.04;.08]),bump,'REGISTRY',[]);
project=fsd.project.reviseEngineeringProject(project,struct('scenarios',{{scenario;s}}));
for j=1:count
    r=fsd.project.runEngineeringScenario(project,"PACK","PACK_"+j);
    project=fsd.project.attachEngineeringResult(project,r);
end
end
