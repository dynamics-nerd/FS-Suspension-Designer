function output=packagingFeasibilityExample(showPlots)
%PACKAGINGFEASIBILITYEXAMPLE Explicit synthetic geometry/materials -> native MAT.
% All dimensions/margins are ASSUMED software inputs, never FS recommendations.
if nargin<1, showPlots=true; end
[concept,definition]=parametricSeedInputs('FRONT');
build=fsd.project.createEngineeringScenario(struct('id',"BUILD_FRONT",'engine',"PARAMETRIC_SEED", ...
    'scope',fsd.model.designScope('AXLE','FRONT'),'inputs',struct('definition',definition)));
p=fsd.project.createEngineeringProject(struct('concept',concept,'scenarios',{{build}}));
constructed=fsd.project.runEngineeringScenario(p,'BUILD_FRONT','BUILT_FRONT');
p=fsd.project.registerParametricSeed(p,constructed); g=p.definition.resources.geometries{1};
d=packagingInputs(g,p.definition.revision); resources=p.definition.resources; resources.packaging={d};
nominal=fsd.project.createPackagingScenario('PACK_NOMINAL','FL','DEMO_PACKAGING', ...
    struct('mode',"NOMINAL",'requested_m',[]),[],'REGISTRY',[]);
bump=fsd.project.createEngineeringScenario(struct('id',"SOLVE_BUMP",'engine',"BUMP", ...
    'scope',fsd.model.designScope('CORNER','FL'),'plan',struct('travel_m',[-.01;0;.01])));
p=fsd.project.reviseEngineeringProject(p,struct('resources',resources,'scenarios',{{build;nominal;bump}}));
static=fsd.project.runEngineeringScenario(p,'PACK_NOMINAL','STATIC_EVIDENCE');
p=fsd.project.attachEngineeringResult(p,static);
source=fsd.project.runEngineeringScenario(p,'SOLVE_BUMP','BUMP_EVIDENCE');
p=fsd.project.attachEngineeringResult(p,source);
sampled=fsd.project.createPackagingScenario('PACK_BUMP','FL','DEMO_PACKAGING', ...
    struct('mode',"BUMP",'requested_m',[-.01;0;.01]),source,'REGISTRY',[]);
p=fsd.project.reviseEngineeringProject(p,struct('scenarios',{{build;nominal;bump;sampled}}));
moving=fsd.project.runEngineeringScenario(p,'PACK_BUMP','MOVING_EVIDENCE');
p=fsd.project.attachEngineeringResult(p,moving);
assert(static.nativePayload.status=="CLEAR_SAMPLED");
assert(moving.nativePayload.status=="COLLISION_DETECTED");
resources=p.definition.resources; changed=d.definitionSI; changed.pairs{1}.requiredClearance_m=.003;
resources.packaging={fsd.packaging.createDefinition(changed)};
revised=fsd.project.reviseEngineeringProject(p,struct('resources',resources));
stale=fsd.project.resultCompatibility(moving,revised);
reusable=fsd.project.resultCompatibility(source,revised);
assert(stale.status=="STALE" && reusable.status=="REUSABLE_DEPENDENCIES");
root=fileparts(fileparts(mfilename('fullpath'))); file=fullfile(root,'output','packaging-feasibility-example.mat');
fsd.project.saveEngineeringProject(p,file,true); loaded=fsd.project.loadEngineeringProject(file);
assert(isequaln(p,loaded)); figures=gobjects(0);
if showPlots
    figures=figure('Name','Packaging — sampled evidence, not manufacturing approval'); ax=axes(figures);
    index=moving.nativePayload.worstCheckIndex;
    fsd.packaging.plotResult(moving.nativePayload,ax,moving.nativePayload.checks{index}.sampleIndex,index);
end
output=struct('static',static,'source',source,'moving',moving,'project',p,'loaded',loaded, ...
    'revised',revised,'stale',stale,'reusable',reusable,'figures',figures);
fprintf('PACKAGING nominal=%s BUMP=%s observed minimum=%.9g m; packaging-only revision=%s / BUMP=%s\n', ...
    static.nativePayload.status,moving.nativePayload.status,moving.nativePayload.minimumObservedDistance_m,stale.status,reusable.status);
fprintf('Explicit simplified solids/sampled poses only; collisions between samples may be missed.\n');
end
