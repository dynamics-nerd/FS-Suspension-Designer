function [space,options] = steeringSynthesisFixture(useRoll,symmetric,role,component)
%STEERINGSYNTHESISFIXTURE ASSUMED native mechanism; broad targets are controls.
if nargin<1, useRoll=false; end
if nargin<2, symmetric=true; end
if nargin<3, role="TIE_ROD_OUTBOARD"; end
if nargin<4, component=1; end
left=threeDimensionalCornerFixture(); right=fsd.geometry.reflectDoubleWishboneGeometry(left);
axle=fsd.model.createAxleGeometry(left,right); steering=fsd.model.createSteeringSystem(axle,1.6,'m');
seeds={left;right}; parameters=cell(2,1); constraints=cell(2,1); targets=cell(0,1);
bindings=["HARDPOINT_X","HARDPOINT_Y","HARDPOINT_Z"];
for j=1:2
    g=seeds{j}; pointId=g.cornerId+"_"+role; point=fsd.model.getPoint(g,pointId); value=point(component);
    p=struct('id',g.cornerId+"_VARIABLE",'quantity',"LENGTH", ...
        'scope',fsd.model.designScope('HARDPOINT',pointId,g.cornerId), ...
        'type',"FREE",'binding',bindings(component),'value',value,'bounds',value+[-.01,.01], ...
        'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Test-only closed coordinate bounds");
    parameters{j}=fsd.model.createDesignParameter(p,'m');
    constraints{j}=fsd.model.createDesignConstraint(struct('id',g.cornerId+"_UBJ_FIXED", ...
        'scope',fsd.model.designScope('HARDPOINT',g.cornerId+"_UBJ",g.cornerId), ...
        'type',"HARDPOINT_FIXED",'strength',"HARD",'position',fsd.model.getPoint(g,g.cornerId+"_UBJ"), ...
        'comparisonTolerance',0,'sourceNote',"Explicit software fixture constraint"),'m');
    d=definition(g.cornerId+"_BUMP","BUMP_STEER","BUMP_"+g.cornerId,"BUMP", ...
        fsd.model.designScope('CORNER',g.cornerId),"WHEEL_TRAVEL",.01,3);
    targets{end+1,1}=fsd.model.createDesignTarget(d,'rad','m'); %#ok<AGROW>
    d=definition(g.cornerId+"_RACK","ROAD_WHEEL_ANGLE","RACK_FRONT","RACK", ...
        fsd.model.designScope('CORNER',g.cornerId),"RACK_TRAVEL",.003,.5);
    d.conditions=struct('wheelTravel_m',[0,0]);
    targets{end+1,1}=fsd.model.createDesignTarget(d,'rad','m'); %#ok<AGROW>
end
for direction=[-1,1]
    d=definition("ACK_"+string(direction+2),"ACKERMANN_ANGLE_ERROR","RACK_FRONT","RACK", ...
        fsd.model.designScope('AXLE','FRONT'),"RACK_TRAVEL",direction*.003,2);
    d.conditions=struct('wheelTravel_m',[0,0]);
    targets{end+1,1}=fsd.model.createDesignTarget(d,'rad','m'); %#ok<AGROW>
end
plan=struct('leftBump',struct('travel_m',[-.01;0;.01]), ...
    'rightBump',struct('travel_m',[-.01;0;.01]),'referenceRackTravel_m',0, ...
    'rack',struct('travel_m',[-.006;-.003;0;.003;.006], ...
    'wheelTravel_m',[0,0],'travelLimits_m',[-.01,.01]));
if useRoll
    plan.roll=struct('angles_rad',[-.01;0;.01],'axleHeave_m',0);
    d=definition("ROLL_ROAD","ROAD_CAMBER","ROLL_FRONT","ROLL", ...
        fsd.model.designScope('CORNER','FL'),"ROLL_ANGLE",0,1);
    d.conditions=struct('axleHeave_m',0);
    targets{end+1,1}=fsd.model.createDesignTarget(d,'rad','rad');
end
spec=fsd.model.createDesignSpecification(struct('id',"STEERING_FIXTURE",'parameters',{parameters}, ...
    'constraints',{constraints},'targets',fsd.model.createSuspensionDesignTargets(targets),'compositeScore',true));
links=strings(0,2); if symmetric, links=["FL_VARIABLE","FR_VARIABLE"]; end
space=fsd.synthesis.createSteeringDesignSpace(left,right,steering,spec,plan,links);
options=struct('maxEvaluations',3,'maxIterations',1,'initialStep',.25,'minimumStep',.25);
end

function d = definition(id,metric,sourceId,family,scope,variable,x,weight)
d=struct('id',id,'metricId',metric,'sourceId',sourceId,'sourceType',family,'scope',scope, ...
    'type',"POINT_TARGET",'strength',"SOFT",'independentVariable',variable,'x',x,'value',0, ...
    'tolerance',1,'normalizationScale',1,'normalizationNote',"Explicit 1 rad availability control", ...
    'weight',weight,'sourceNote',"Test-only availability control, not an FS target");
end
