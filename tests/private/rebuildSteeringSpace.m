function space = rebuildSteeringSpace(original,definition,plan,links,seeds,steering)
%REBUILDSTEERINGSPACE Canonical test edits, never patch a derived identity.
if nargin<3, plan=original.plan; end
if nargin<4, links=original.symmetryLinks; end
if nargin<5, seeds={original.seedAxle.leftGeometry;original.seedAxle.rightGeometry}; end
if nargin<6
    steering=fsd.model.createSteeringSystem(fsd.model.createAxleGeometry(seeds{1},seeds{2}), ...
        original.seedSteering.rearAxleX_m,'m');
end
space=fsd.synthesis.createSteeringDesignSpace(seeds{1},seeds{2},steering, ...
    fsd.model.createDesignSpecification(definition),plan,links);
end
