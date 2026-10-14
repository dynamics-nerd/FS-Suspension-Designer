function [project,concept,options] = rulePhysicalInputFixture(role,id,value,referenceStatus,confirmation)
%RULEPHYSICALINPUTFIXTURE Synthetic V16-F-01 case, not a Formula Student rule.
if nargin<1, role="RULE"; end
if nargin<2, id="VEHICLE_MASS"; end
if nargin<3, value=125; end
if nargin<4, referenceStatus="UNVERIFIED"; end
if nargin<5, confirmation="DECLARED"; end
ids=["VEHICLE_MASS","DRIVER_MASS","WHEELBASE","FRONT_TRACK","REAR_TRACK","CG_X","CG_Y","CG_Z"];
values=[125,64.8,2.4,1.4,1.2,.9,0,.37]; units=["kg","kg","m","m","m","m","m","m"];
parameters=cell(numel(ids),1);
for j=1:numel(ids)
    parameters{j}=fsd.project.createConceptParameter(ids(j),struct('type',"ASSUMED",'value',values(j), ...
        'sourceKind',"ASSUMED",'availability',"ASSUMED",'sourceNote',"Synthetic audit hypothesis, not measured"),units(j));
end
index=find(ids==id);
if isempty(index)
    catalog=fsd.project.conceptParameterCatalog(); entry=catalog(string({catalog.id})==id);
    unit=entry.unit;
else
    unit=units(index);
end
d=struct('type',role,'value',value,'availability',"KNOWN",'sourceKind',"KNOWN", ...
    'sourceNote',"Synthetic audit declaration, not an actual regulation",'confirmation',confirmation, ...
    'origin',struct('reference',"FICTITIOUS_AUDIT_REFERENCE"));
if role=="ASSUMED", d.availability="ASSUMED"; d.sourceKind="ASSUMED"; end
if role=="DERIVED"
    d.availability="DERIVED"; d.sourceKind="DERIVED"; d.derivationReference="Explicit synthetic calculation reference";
end
if role=="RULE"
    quantity="LENGTH"; if contains(id,"MASS"), quantity="MASS"; end
    if contains(id,"FRACTION"), quantity="FRACTION"; end
    d.ruleReference=struct('organizer',"FICTITIOUS_TEST_ONLY",'version',"AUDIT_FIXTURE", ...
        'ruleId',"NOT_A_REAL_RULE",'quantity',quantity,'source',"Synthetic negative control", ...
        'status',referenceStatus,'applicability',"Test only; no regulatory compliance claim");
end
if isempty(value), d.availability="NOT_PROVIDED"; end
if role=="RANGE", d.bounds=[100,150]; end
p=fsd.project.createConceptParameter(id,d,unit);
if isempty(index), parameters{end+1,1}=p; else, parameters{index}=p; end
concept=fsd.project.createVehicleConcept(struct('id',"RULE_AUDIT",'massConvention',"EXCLUDES_DRIVER",'parameters',{parameters}));
% Explicit rectangular contacts and symmetric closure are test assumptions.
options=struct('gravity_mps2',9.7,'gravitySourceKind',"ASSUMED",'gravitySourceNote',"Synthetic audit gravity", ...
    'operatingConfiguration',"SYNTHETIC_WITH_DRIVER",'contactPolicy',"EXPLICIT", ...
    'contactPoints_m',[0,-.7,0;0,.7,0;2.4,-.6,0;2.4,.6,0], ...
    'contactSourceKind',"ASSUMED",'contactSourceNote',"Explicit assumed rectangular test contacts", ...
    'loadCaseDefinition',struct('mode',"ASSUMED_SYMMETRIC_BASELINE",'sourceKind',"ASSUMED"));
scenario=fsd.project.createEngineeringScenario(struct('id',"STATIC",'engine',"STATIC_LOADS", ...
    'scope',fsd.model.designScope('VEHICLE','VEHICLE'),'plan',options));
project=fsd.project.createEngineeringProject(struct('concept',concept,'scenarios',{{scenario}}));
end
