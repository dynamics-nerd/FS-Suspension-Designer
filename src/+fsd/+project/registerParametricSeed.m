function project = registerParametricSeed(project,result,steering)
%REGISTERPARAMETRICSEED Explicit atomic adoption; preserve history and origin binding.
if nargin<3, steering=[]; end
fsd.project.validateEngineeringProject(project); fsd.project.validateEngineeringResult(result);
projectRequire(ismember(result.engine,["PARAMETRIC_SEED","PARAMETRIC_BUMP"]), 'Result is not a parametric construction.');
compatibility=fsd.project.resultCompatibility(result,project);
projectRequire(ismember(compatibility.status,["CURRENT_EXECUTION","REUSABLE_DEPENDENCIES"]), 'Cannot adopt an obsolete seed.');
seed=result.nativePayload.seed; projectRequire(seed.nominalStatus=="VALID",'Only valid nominal seeds can be registered.');
resources=project.definition.resources; corners=cellfun(@(g)g.cornerId,seed.geometries);
keep=~cellfun(@(g)ismember(g.cornerId,corners),resources.geometries);
resources.geometries=[resources.geometries(keep);seed.geometries];
bindings={}; if isfield(resources,'seedBindings'), bindings=resources.seedBindings; end
keep=true(numel(bindings),1);
for j=1:numel(bindings)
    previous=cellfun(@(g)g.cornerId,bindings{j}.construction.geometries);
    if any(ismember(previous,corners))
        projectRequire(all(ismember(previous,corners)), 'Adopting one side of a generated pair requires an explicit resource revision.');
        keep(j)=false;
    end
end
binding=struct('scenarioId',result.scenarioAtExecution.definition.id,'projectId',result.projectId, ...
    'projectRevision',result.projectRevision,'construction',seed,'identity',[]);
binding.identity=struct('scenarioId',binding.scenarioId,'projectId',binding.projectId, ...
    'projectRevision',binding.projectRevision,'constructionIdentity',seed.identity);
resources.seedBindings=[bindings(keep);{binding}];
if ~isempty(steering)
    fsd.model.validateSteeringSystemGeometry(steering);
    projectRequire(~isempty(seed.axle) && isequaln(steering.frontAxleGeometry,seed.axle), 'Explicit steering does not match the generated axle.');
    refs=seed.referenceParameters; i=cellfun(@(p)p.definitionSI.id=="WHEELBASE",refs);
    wb=refs{i}.definitionSI.value; tol=fsd.model.numericTolerances();
    projectRequire(abs(steering.rearAxleX_m-wb)<=tol.AbsTol_m+tol.RelTol*max([1,abs(wb),abs(steering.rearAxleX_m)]), ...
        'Explicit steering rear reference differs from the physical concept wheelbase.');
    resources.steerings={steering};
end
% Native registry validation rejects still-associated incompatible ACT/MECH/RACK.
project=fsd.project.reviseEngineeringProject(project,struct('resources',resources));
if ~any(cellfun(@(r)r.id==result.id,project.definition.results))
    project=fsd.project.attachEngineeringResult(project,result);
end
end
