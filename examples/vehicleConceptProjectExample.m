function output = vehicleConceptProjectExample(showPlots)
%VEHICLECONCEPTPROJECTEXAMPLE Partial concept -> explicit audited seed -> synthesis.
% All numbers and inherited geometry are ASSUMED benchmark inputs, not FS advice.
if nargin<1, showPlots=true; end
ids=["VEHICLE_MASS","DRIVER_MASS","WHEELBASE","FRONT_TRACK","REAR_TRACK"];
values=[200,70,1.6,1.3,1.2]; units=["kg","kg","m","m","m"]; parameters=cell(5,1);
for j=1:5
    parameters{j}=fsd.project.createConceptParameter(ids(j),struct('type',"ASSUMED",'value',values(j), ...
        'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Explicit illustrative workflow input; not measured", ...
        'origin',struct('actor',"WORKFLOW_EXAMPLE",'limitations',"No Formula Student performance recommendation")),units(j));
end
concept=fsd.project.createVehicleConcept(struct('id',"WORKFLOW_EXAMPLE",'vehicleName',"Illustrative FS concept", ...
    'massConvention',"EXCLUDES_DRIVER",'parameters',{parameters}));
derivation=fsd.project.deriveVehicleConcept(concept); assert(derivation.values{1}.value==270 && isempty(derivation.vehicle));
partial=fsd.project.createEngineeringProject(struct('concept',concept,'derivations',{{derivation}}));
initialReadiness=fsd.project.designReadiness(partial);
assert(all(cellfun(@(r)r.status=="MISSING_DATA",initialReadiness)));
root=fileparts(fileparts(mfilename('fullpath')));
partialFile=fullfile(root,'output','vehicle-concept-partial.mat');
fsd.project.saveEngineeringProject(partial,partialFile,true);
assert(isequaln(partial,fsd.project.loadEngineeringProject(partialFile)));
% Existing audited v0.15 example supplies EXPLICIT seed/spec/physical reference.
% Its own reference/search/repeat/pull work is separate from this scenario budget.
native=actuationSynthesisExample(false); s=native.space;
origins=cell(numel(s.specification.definitionSI.targets.definitionSI.targets),1);
for j=1:numel(origins)
    t=s.specification.definitionSI.targets.definitionSI.targets{j};
    origins{j}=struct('targetId',t.definitionSI.id,'kind',"DECLARED_REFERENCE", ...
        'reference',"actuationSynthesisExample: independently solved reachable native reference", ...
        'note',"ASSUMED test-only reference, not an optimal motion ratio recommendation");
end
options=native.result.search.options;
scenario=fsd.project.createEngineeringScenario(struct('id',"ACT_DESIGN",'engine',"ACTUATION_SYNTHESIS", ...
    'scope',fsd.model.designScope('CORNER','FL'),'plan',s.plan,'options',options, ...
    'specification',s.specification,'targetOrigins',{origins}));
bump=fsd.project.createEngineeringScenario(struct('id',"FL_BUMP",'engine',"BUMP", ...
    'scope',fsd.model.designScope('CORNER','FL'),'plan',struct('travel_m',s.plan.travel_m)));
resources=struct('geometries',{{s.seed}},'actuations',{{s.seedActuation}},'mechanicals',{{s.seedMechanical}});
project=fsd.project.reviseEngineeringProject(partial,struct('resources',resources,'scenarios',{{scenario;bump}}));
assert(fsd.project.designReadiness(project,'ACT_DESIGN').status=="READY");
analysisResult=fsd.project.runEngineeringScenario(project,'FL_BUMP','FL_BUMP_RESULT');
result=fsd.project.runEngineeringScenario(project,'ACT_DESIGN','ACT_RESULT');
fsd.project.validateEngineeringResult(result);
assert(result.nativePayload.search.evaluationCount==8 && result.nativePayload.search.records{result.nativePayload.selectedIndex}.score==0);
project=fsd.project.attachEngineeringResult(project,result);
project=fsd.project.attachEngineeringResult(project,analysisResult);
assert(fsd.project.resultCompatibility(result,project).status=="CURRENT_EXECUTION");
d=concept.definitionSI; index=cellfun(@(p)p.id=="VEHICLE_MASS",d.parameters);
d.parameters{index}=fsd.project.createConceptParameter('VEHICLE_MASS',struct('type',"ASSUMED",'value',210, ...
    'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Explicit alternative vehicle mass"),'kg');
revised=fsd.project.reviseEngineeringProject(project,struct('concept',fsd.project.createVehicleConcept(d)));
compatibility=fsd.project.resultCompatibility(result,revised);
assert(compatibility.status=="REUSABLE_DEPENDENCIES");
changed=scenario.definition; changed.options.maxEvaluations=options.maxEvaluations+1;
numerical=fsd.project.reviseEngineeringProject(revised,struct('scenarios',{{fsd.project.createEngineeringScenario(changed);bump}}));
assert(fsd.project.resultCompatibility(result,numerical).status=="STALE");
file=fullfile(root,'output','vehicle-concept-project-example.mat');
fsd.project.saveEngineeringProject(numerical,file,true); loaded=fsd.project.loadEngineeringProject(file);
assert(isequaln(loaded,numerical));
figures=gobjects(0,1); if showPlots, figures=fsd.synthesis.plotActuationSynthesisResult(result.nativePayload); end
output=struct('partial',partial,'derivation',derivation,'initialReadiness',{initialReadiness}, ...
    'project',project,'result',result,'analysisResult',analysisResult,'massRevision',revised, ...
    'numericalRevision',numerical,'compatibility',compatibility,'loaded',loaded,'nativeReference',native, ...
    'externalPhysicalSweepInvocations',22,'workflowBumpSweeps',9,'workflowActuationSweeps',8, ...
    'workflowMechanicalAnalyses',8,'figures',figures);
fprintf('PROJECT: partial mass 270 kg; no CG/seed inferred. ACT E8/BUMP8/ACT8/MECH8 score -> 0.\n');
fprintf('External v0.15 preparation: 22 physical sweeps; separate analysis: 1 BUMP. Mass reusable; options stale.\n');
end
