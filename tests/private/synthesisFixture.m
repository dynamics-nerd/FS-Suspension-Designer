function [space,options] = synthesisFixture(axes)
%SYNTHESISFIXTURE Independent 3D fixture; reachable known-coordinate target.
if nargin<1, axes=[3,3]; end
seed=threeDimensionalCornerFixture(); xyz=seed.hardpoints.xyz_m; ids=seed.hardpoints.ids;
parameters=cell(numel(axes),1); desired=xyz;
for i=1:numel(axes)
    axis=axes(i); nominal=xyz(i,axis); desired(i,axis)=nominal+.005;
    labels=["HARDPOINT_X","HARDPOINT_Y","HARDPOINT_Z"];
    d=struct('id',"VAR_"+string(i),'quantity',"LENGTH",'scope',fsd.model.designScope('HARDPOINT',ids(i),'FL'), ...
        'type',"FREE",'binding',labels(axis),'value',nominal,'bounds',nominal+[-.01,.01], ...
        'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Test-only +/-10mm fixture region");
    parameters{i}=fsd.model.createDesignParameter(d,'m');
end
reference=fsd.model.createDoubleWishboneGeometry('FL',ids,desired,'m',seed.wheel.wheelAxis, ...
    struct('sourceKind',"ASSUMED",'sourceNote',"Reachable target test fixture"));
z=[-.01;0;.01]; sweep=fsd.kinematics.solveBumpSweep(reference,z,'m'); a=fsd.analysis.analyzeBumpSweep(reference,sweep);
base=struct('id',"CAMBER_OBJECTIVE",'metricId',"CAMBER",'sourceType',"BUMP",'sourceId',"BUMP_FL", ...
    'scope',fsd.model.designScope('CORNER','FL'),'type',"CURVE_TARGET",'strength',"SOFT", ...
    'independentVariable',"WHEEL_TRAVEL",'x',z,'value',a.camber_rad,'tolerance',1e-7, ...
    'normalizationScale',.01,'normalizationNote',"Test-only angle scale",'weight',1,'sourceNote',"Reachable test reference only");
targets={fsd.model.createDesignTarget(base,'rad','m')};
base.id="TOE_OBJECTIVE"; base.metricId="TOE"; base.value=a.toe_rad;
targets{2,1}=fsd.model.createDesignTarget(base,'rad','m');
fixed=fsd.model.createDesignConstraint(struct('id',"FIXED_UBJ",'scope',fsd.model.designScope('HARDPOINT','FL_UBJ','FL'), ...
    'type',"HARDPOINT_FIXED",'strength',"HARD",'position',xyz(3,:),'comparisonTolerance',0,'sourceNote',"Fixed test outboard"),'m');
spec=fsd.model.createDesignSpecification(struct('id',"SYNTH_TEST",'parameters',{parameters},'constraints',{{fixed}}, ...
    'targets',fsd.model.createSuspensionDesignTargets(targets),'compositeScore',true));
space=fsd.synthesis.createDesignSpace(seed,spec,struct('travel_m',z));
options=struct('maxEvaluations',24,'maxIterations',12,'initialStep',.25,'minimumStep',1/128,'stopAtScore',1e-8);
end
