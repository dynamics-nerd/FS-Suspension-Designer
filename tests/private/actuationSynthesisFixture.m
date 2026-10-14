function [space,options] = actuationSynthesisFixture(architecture,corner,useMechanical)
%ACTUATIONSYNTHESISFIXTURE Native illustrative mechanisms, broad availability controls.
if nargin<1, architecture="PUSHROD"; end
if nargin<2, corner="FL"; end
if nargin<3, useMechanical=true; end
[g,a,m]=actuationSynthesisSeed(architecture,corner);
point=fsd.model.getActuationDesignPoint(a,g.cornerId+"_DAMPER_CHASSIS");
parameters=cell(2,1); bindings=["HARDPOINT_Y","HARDPOINT_Z"];
for j=1:2
    value=point(j+1);
    p=struct('id',"MOUNT_"+string(j),'quantity',"LENGTH", ...
        'scope',fsd.model.designScope('HARDPOINT',g.cornerId+"_DAMPER_CHASSIS",g.cornerId), ...
        'type',"FREE",'binding',bindings(j),'value',value,'bounds',value+[-.01,.01], ...
        'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Explicit test-only coordinate bounds");
    parameters{j}=fsd.model.createDesignParameter(p,'m');
end
c=fsd.model.createDesignConstraint(struct('id',"ROCKER_LINE_FIXED",'type',"HARDPOINT_FIXED",'strength',"HARD", ...
    'scope',fsd.model.designScope('HARDPOINT',g.cornerId+"_ROCKER_AXIS_POINT",g.cornerId), ...
    'position',a.rocker.axis.point_m,'comparisonTolerance',0,'sourceNote',"Fixed oriented-line control, not bearings"),'m');
targets=cell(0,1);
targets{1,1}=target("MR","MOTION_RATIO","ACTUATION","ACT",0,0,1,1,2);
targets{2,1}=target("TRAVEL","DAMPER_COMPRESSION","ACTUATION","ACT",.01,0,1,.01,1);
targets{3,1}=target("ANGLE","ROCKER_ANGLE","ACTUATION","ACT",.01,0,1,1,1);
plan=struct('travel_m',(-.02:.005:.02)');
if useMechanical
    targets{4,1}=target("RATE","TANGENT_WHEEL_RATE","MECHANICAL","MECH",0,0,1e6,30000,1);
    plan.wheelVelocity_m_per_s=0; % explicit prescribed rest, not inferred dynamics
else
    m=[];
end
spec=fsd.model.createDesignSpecification(struct('id',"ACTUATION_FIXTURE",'parameters',{parameters}, ...
    'constraints',{{c}},'targets',fsd.model.createSuspensionDesignTargets(targets),'compositeScore',true));
space=fsd.synthesis.createActuationDesignSpace(g,a,m,spec,plan);
options=struct('maxEvaluations',3,'maxIterations',1,'initialStep',.25,'minimumStep',.25);

    function q = target(id,metric,family,source,x,value,tolerance,scale,weight)
        quantityUnit='1';
        if metric=="DAMPER_COMPRESSION", quantityUnit='m'; end
        if metric=="ROCKER_ANGLE", quantityUnit='rad'; end
        if metric=="TANGENT_WHEEL_RATE", quantityUnit='N/m'; end
        q=fsd.model.createDesignTarget(struct('id',id,'metricId',metric,'sourceType',family,'sourceId',source, ...
            'scope',fsd.model.designScope('CORNER',g.cornerId),'type',"POINT_TARGET",'strength',"SOFT", ...
            'independentVariable',"WHEEL_TRAVEL",'x',x,'value',value,'tolerance',tolerance, ...
            'normalizationScale',scale,'normalizationNote',"Explicit test-only availability scale", ...
            'weight',weight,'sourceNote',"Broad availability control, not an FS target"),quantityUnit,'m');
    end
end
