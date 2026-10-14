function [concept,options] = conceptWorkflowFixture()
%CONCEPTWORKFLOWFIXTURE Explicit analytic M270/g10/CG(.8,0,.3), not FS values.
ids=["VEHICLE_MASS","DRIVER_MASS","WHEELBASE","FRONT_TRACK","REAR_TRACK","CG_X","CG_Y","CG_Z"];
values=[200,70,1.6,1.3,1.2,.8,0,.3]; units=["kg","kg","m","m","m","m","m","m"];
parameters=cell(numel(ids),1);
for j=1:numel(ids)
    parameters{j}=fsd.project.createConceptParameter(ids(j),struct('type',"ASSUMED",'value',values(j), ...
        'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Explicit analytic test data"),units(j));
end
concept=fsd.project.createVehicleConcept(struct('id',"CONCEPT_TEST",'massConvention',"EXCLUDES_DRIVER",'parameters',{parameters}));
options=struct('gravity_mps2',10,'gravitySourceKind',"ASSUMED",'gravitySourceNote',"Explicit analytic test gravity", ...
    'operatingConfiguration',"TEST_WITH_DRIVER",'contactPolicy',"CONCEPTUAL_HORIZONTAL", ...
    'contactSourceNote',"Explicit assumed flat rectangular contact layout", ...
    'loadCaseDefinition',struct('mode',"ASSUMED_SYMMETRIC_BASELINE",'sourceKind',"ASSUMED"));
end
