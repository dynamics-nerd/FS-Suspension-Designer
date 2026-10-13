function [steering,changes,diagnostics] = steeringBuildCore(space,x_m)
%STEERINGBUILDCORE Reconstruct the entire mechanism; static lengths are derived.
[axle,changes]=axleBuildCore(space,x_m);
steering=fsd.model.createSteeringSystem(axle,space.seedSteering.rearAxleX_m,'m');
diagnostics=struct('seedTieRodLength_m',tieLengths(space.seedAxle), ...
    'tieRodLength_m',tieLengths(axle),'seedRack',space.seedSteering.rackGeometry, ...
    'rack',steering.rackGeometry,'referenceRackTravel_m',space.plan.referenceRackTravel_m, ...
    'verificationDomain',"NOMINAL_GEOMETRY_ONLY",'collisionStatus',"NOT_CHECKED");
end

function lengths = tieLengths(axle)
geometries={axle.leftGeometry;axle.rightGeometry}; lengths=zeros(1,2);
for j=1:2
    g=geometries{j}; lengths(j)=norm(fsd.model.getPoint(g,g.cornerId+"_TIE_ROD_OUTBOARD")- ...
        fsd.model.getPoint(g,g.cornerId+"_TIE_ROD_INBOARD"));
end
end
