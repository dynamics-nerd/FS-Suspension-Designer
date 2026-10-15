function output = conceptToSeedExample(showPlots)
%CONCEPTTOSEEDEXAMPLE Partial concept -> decisions -> native geometry/BUMP/search/MAT.
% Every number/target here is an ASSUMED SOFTWARE FIXTURE, not FS setup advice.
if nargin<1, showPlots=true; end
[concept,definition]=parametricSeedInputs('FRONT');
partialDefinition=fsd.construction.createParametricSeedDefinition(struct('id',"PARAMETRIC_FRONT",'cornerId',"FRONT",'symmetry',"MIRROR_FL"));
scenario=fsd.project.createEngineeringScenario(struct('id',"BUILD_FRONT",'engine',"PARAMETRIC_SEED", ...
    'scope',fsd.model.designScope('AXLE','FRONT'),'inputs',struct('definition',partialDefinition)));
project=fsd.project.createEngineeringProject(struct('concept',concept,'scenarios',{{scenario}}));
incomplete=fsd.project.designReadiness(project,'BUILD_FRONT'); assert(incomplete.status=="MISSING_DATA");
root=fileparts(fileparts(mfilename('fullpath'))); file=fullfile(root,'output','concept-to-seed-example.mat');
fsd.project.saveEngineeringProject(project,file,true); assert(isequaln(project,fsd.project.loadEngineeringProject(file)));
sd=scenario.definition; sd.inputs.definition=definition; scenario=fsd.project.createEngineeringScenario(sd);
project=fsd.project.reviseEngineeringProject(project,struct('scenarios',{{scenario}}));
nominal=fsd.project.runEngineeringScenario(project,'BUILD_FRONT','GENERATED_FRONT');
assert(nominal.nativePayload.seed.nominalStatus=="VALID");
seed=nominal.nativePayload.seed; project=fsd.project.registerParametricSeed(project,nominal);
sd.id="CHECK_FRONT"; sd.engine="PARAMETRIC_BUMP"; sd.plan=struct('travel_m',[-.01;0;.01]);
checkScenario=fsd.project.createEngineeringScenario(sd);
project=fsd.project.reviseEngineeringProject(project,struct('scenarios',{{scenario;checkScenario}}));
physical=fsd.project.runEngineeringScenario(project,'CHECK_FRONT','FRONT_BUMP');
assert(physical.nativePayload.bumpCheck.status=="SAMPLED_PASS"); project=fsd.project.attachEngineeringResult(project,physical);
% Optional steering is a separate explicit action, using declared tie endpoints.
steering=fsd.project.createSeedSteering(seed);
project=fsd.project.registerParametricSeed(project,nominal,steering);
g=seed.geometries{1}; [~,desiredDefinition]=parametricSeedInputs('FRONT',.005);
refs=seed.referenceParameters; reference=fsd.construction.buildParametricSeed(desiredDefinition,refs);
assert(reference.nominalStatus=="VALID");
travel=[-.01;0;.01]; referenceSweep=fsd.kinematics.solveBumpSweep(reference.geometries{1},travel,'m');
a=fsd.analysis.analyzeBumpSweep(reference.geometries{1},referenceSweep);
parameters=cell(2,1);
for j=1:2
    id=g.hardpoints.ids(j); z=g.hardpoints.xyz_m(j,3);
    parameters{j}=fsd.model.createDesignParameter(struct('id',"UPPER_Z_"+string(j),'quantity',"LENGTH", ...
        'scope',fsd.model.designScope('HARDPOINT',id,'FL'),'type',"FREE",'binding',"HARDPOINT_Z", ...
        'value',z,'bounds',z+[-.01,.01],'availability',"ASSUMED",'sourceKind',"ASSUMED", ...
        'sourceNote',"Explicit illustrative search bounds"),'m');
end
d=struct('id',"CAMBER_TARGET",'metricId',"CAMBER",'sourceType',"BUMP",'sourceId',"BUMP_FL", ...
    'scope',fsd.model.designScope('CORNER','FL'),'type',"CURVE_TARGET",'strength',"SOFT", ...
    'independentVariable',"WHEEL_TRAVEL",'x',travel,'value',a.camber_rad,'tolerance',1e-7, ...
    'normalizationScale',.01,'normalizationNote',"ASSUMED software scale",'weight',1, ...
    'sourceNote',"Illustrative reachable reference, not a vehicle-performance target");
targets={fsd.model.createDesignTarget(d,'rad','m')}; d.id="TOE_TARGET"; d.metricId="TOE"; d.value=a.toe_rad;
targets{2,1}=fsd.model.createDesignTarget(d,'rad','m');
hard=rmfield(d,{'value','tolerance','weight'}); hard.id="TOE_LIMIT"; hard.type="CURVE_BAND";
hard.strength="HARD"; hard.lower=-.2; hard.upper=.2; targets{3,1}=fsd.model.createDesignTarget(hard,'rad','m');
spec=fsd.model.createDesignSpecification(struct('id',"PARAMETRIC_SEARCH",'parameters',{parameters}, ...
    'targets',fsd.model.createSuspensionDesignTargets(targets),'compositeScore',true));
options=struct('maxEvaluations',28,'maxIterations',12,'initialStep',.25,'minimumStep',1/128,'stopAtScore',1e-8);
searchScenario=fsd.project.createEngineeringScenario(struct('id',"SEARCH_FL",'engine',"CORNER_SYNTHESIS", ...
    'scope',fsd.model.designScope('CORNER','FL'),'specification',spec,'plan',struct('travel_m',travel),'options',options));
project=fsd.project.reviseEngineeringProject(project,struct('scenarios',{{scenario;checkScenario;searchScenario}}));
search=fsd.project.runEngineeringScenario(project,'SEARCH_FL','PARAMETRIC_SYNTHESIS');
result=search.nativePayload; fsd.synthesis.validateSynthesisResult(result);
assert(isfinite(result.selectedIndex) && result.search.records{result.selectedIndex}.score<result.search.records{1}.score);
assert(isequaln(result.problem.seed,g),'Generated geometry must enter native synthesis directly.');
project=fsd.project.attachEngineeringResult(project,search);
fsd.project.saveEngineeringProject(project,file,true); loaded=fsd.project.loadEngineeringProject(file); assert(isequaln(project,loaded));
figures=gobjects(0); if showPlots, handles=fsd.geometry.plotDoubleWishboneGeometry(g); figures=handles.figure; end
output=struct('incompleteReadiness',incomplete,'nominal',nominal,'seed',seed,'physical',physical, ...
    'steering',steering,'search',search,'project',project,'loaded',loaded,'figures',figures);
fprintf('PARAMETRIC: nominal %s, BUMP %s, synthesis E%d score %.12g -> %.12g.\n', ...
    seed.nominalStatus,physical.nativePayload.bumpCheck.status,result.search.evaluationCount, ...
    result.search.records{1}.score,result.search.records{result.selectedIndex}.score);
fprintf('Illustrative explicit decisions only; no continuous feasibility, CAD, rules or performance certification.\n');
end
