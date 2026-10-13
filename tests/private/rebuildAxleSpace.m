function space = rebuildAxleSpace(original,definition,plan,links,seeds)
%REBUILDAXLESPACE Test-only canonical factory after explicit fixture edits.
if nargin<3, plan=original.plan; end
if nargin<4, links=original.symmetryLinks; end
if nargin<5, seeds={original.seedAxle.leftGeometry;original.seedAxle.rightGeometry}; end
space=fsd.synthesis.createAxleDesignSpace(seeds{1},seeds{2},fsd.model.createDesignSpecification(definition),plan,links);
end
