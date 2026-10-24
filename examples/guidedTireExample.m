function [project,result]=guidedTireExample()
%GUIDEDTIREEXAMPLE Synthetic native library/study, no provider or vehicle solves.
[d,states,request]=tireCharacterizationInputs;
project=fsd.project.createEngineeringProject(struct('concept',fsd.project.createVehicleConcept(struct('id',"SYNTHETIC_TIRE_EXAMPLE"))));
[project,tire]=fsd.project.registerTire(project,d);
ids=["FL","FR","RL","RR"]; assignments=cell(4,1);
for k=1:4
    assignments{k}=struct('cornerId',ids(k),'tireId',tire.definition.id,'tireRevision',1);
end
project=fsd.project.assignTires(project,assignments);
scenario=fsd.project.createEngineeringScenario(struct('id',"TIRE_CHARACTERIZATION",'engine',"TIRE_CHARACTERIZATION", ...
    'scope',fsd.model.designScope('VEHICLE','VEHICLE'), ...
    'inputs',struct('tireId',tire.definition.id,'tireRevision',1), ...
    'plan',struct('states',states,'request',request)));
project=fsd.project.reviseEngineeringProject(project,struct('scenarios',{{scenario}}));
[result,project]=fsd.project.runEngineeringScenario(project,scenario.definition.id,'SYNTHETIC_TIRE_CURVE');
end
