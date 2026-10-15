function f = parametricSeedFixture(corner)
%PARAMETRICSEEDFIXTURE Independent known old 3D mechanism reconstructed from decisions.
if nargin<1, corner='FL'; end
[concept,definition]=parametricSeedInputs(corner);
ids=fsd.construction.seedReferenceIds(definition); ps=concept.definitionSI.parameters;
refs=cell(numel(ids),1);
for j=1:numel(ids), i=cellfun(@(p)p.id==ids(j),ps); refs{j}=ps{i}.parameter; end
kind="CORNER"; if string(corner)=="FRONT", kind="AXLE"; end
scope=fsd.model.designScope(kind,corner);
scenario=fsd.project.createEngineeringScenario(struct('id',"BUILD",'engine',"PARAMETRIC_SEED", ...
    'scope',scope,'inputs',struct('definition',definition)));
project=fsd.project.createEngineeringProject(struct('concept',concept,'scenarios',{{scenario}}));
f=struct('concept',concept,'definition',definition,'references',{refs},'project',project);
end
