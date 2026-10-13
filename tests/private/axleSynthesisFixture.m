function [space,options] = axleSynthesisFixture(useRoll,axleId,component,symmetric)
%AXLESYNTHESISFIXTURE ASSUMED geometry/bounds; broad targets are test controls.
if nargin<1, useRoll=false; end
if nargin<2, axleId="FRONT"; end
if nargin<3, component=3; end
if nargin<4, symmetric=false; end
left=threeDimensionalCornerFixture();
if axleId=="REAR"
    left=fsd.model.createDoubleWishboneGeometry('RL',"RL_"+fsd.model.requiredHardpointRoles(), ...
        left.hardpoints.xyz_m+[1.6,0,0],'m',left.wheel.wheelAxis, ...
        struct('sourceKind',"ASSUMED",'sourceNote',"Test-only 1.6 m rear translation"));
end
right=fsd.geometry.reflectDoubleWishboneGeometry(left); seeds={left;right};
parameters=cell(2,1); constraints=cell(2,1); targets=cell(0,1); axes=["HARDPOINT_X","HARDPOINT_Y","HARDPOINT_Z"];
for j=1:2
    g=seeds{j}; value=g.hardpoints.xyz_m(1,component);
    p=struct('id',g.cornerId+"_VARIABLE",'quantity',"LENGTH",'scope',fsd.model.designScope('HARDPOINT',g.hardpoints.ids(1),g.cornerId), ...
        'type',"FREE",'binding',axes(component),'value',value,'bounds',value+[-.01,.01], ...
        'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Test-only closed coordinate interval");
    parameters{j}=fsd.model.createDesignParameter(p,'m');
    constraints{j}=fsd.model.createDesignConstraint(struct('id',g.cornerId+"_UBJ_FIXED", ...
        'scope',fsd.model.designScope('HARDPOINT',g.cornerId+"_UBJ",g.cornerId),'type',"HARDPOINT_FIXED", ...
        'strength',"HARD",'position',fsd.model.getPoint(g,g.cornerId+"_UBJ"),'comparisonTolerance',0, ...
        'sourceNote',"Explicit test outboard constraint"),'m');
    t=struct('id',g.cornerId+"_CAMBER",'metricId',"CAMBER",'sourceId',"BUMP_"+g.cornerId,'sourceType',"BUMP", ...
        'scope',fsd.model.designScope('CORNER',g.cornerId),'type',"POINT_TARGET",'strength',"SOFT", ...
        'independentVariable',"WHEEL_TRAVEL",'x',0,'value',0,'tolerance',1,'normalizationScale',1, ...
        'normalizationNote',"Broad 1 rad test control, not an FS target",'weight',1,'sourceNote',"Availability test only");
    targets{end+1,1}=fsd.model.createDesignTarget(t,'rad','m'); %#ok<AGROW>
    if useRoll
        t.id=g.cornerId+"_ROAD_CAMBER"; t.metricId="ROAD_CAMBER"; t.sourceId="ROLL_AXLE"; t.sourceType="ROLL";
        t.independentVariable="ROLL_ANGLE"; t.conditions=struct('axleHeave_m',0);
        targets{end+1,1}=fsd.model.createDesignTarget(t,'rad','rad'); %#ok<AGROW>
    end
end
spec=fsd.model.createDesignSpecification(struct('id',"AXLE_FIXTURE",'parameters',{parameters},'constraints',{constraints}, ...
    'targets',fsd.model.createSuspensionDesignTargets(targets),'compositeScore',true));
plan=struct('leftBump',struct('travel_m',[-.01;0;.01]),'rightBump',struct('travel_m',[-.01;0;.01]));
if useRoll, plan.roll=struct('angles_rad',[-.01;0;.01],'axleHeave_m',0); end
links=strings(0,2);
if symmetric, links=[left.cornerId+"_VARIABLE",right.cornerId+"_VARIABLE"]; end
space=fsd.synthesis.createAxleDesignSpace(left,right,spec,plan,links);
options=struct('maxEvaluations',3,'maxIterations',2,'initialStep',.25,'minimumStep',.25);
end
