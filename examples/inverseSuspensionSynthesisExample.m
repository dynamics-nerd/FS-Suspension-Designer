function output = inverseSuspensionSynthesisExample(showPlots)
%INVERSESUSPENSIONSYNTHESISEXAMPLE Real inboard mutation, fresh BUMP and bounded search.
% Every geometric range/angle/weight below is ASSUMED for demonstration ONLY.
% The desired curves come from a separately solved reachable reference geometry.
% This is not a Formula Student setup recommendation, CAD or global optimum.
if nargin<1, showPlots=true; end
ids="FL_"+fsd.model.requiredHardpointRoles();
xyz=[-.120,-.380,.360;.100,-.420,.340;.030,-.600,.420; ...
    -.110,-.390,.140;.120,-.410,.160;-.020,-.600,.080; ...
    .040,-.390,.250;.050,-.570,.230;0,-.650,.250;0,-.650,0];
provenance=struct('sourceKind',"ASSUMED",'sourceNote',"Illustrative 3D fixture; no manufacturing recommendation");
seed=fsd.model.createDoubleWishboneGeometry('FL',ids,xyz,'m',[0,-1,0],provenance);
travel=[-.01;0;.01]; desired=xyz; desired(1:2,3)=desired(1:2,3)+.005;
reference=fsd.model.createDoubleWishboneGeometry('FL',ids,desired,'m',[0,-1,0],provenance);
referenceSweep=fsd.kinematics.solveBumpSweep(reference,travel,'m');
referenceAnalysis=fsd.analysis.analyzeBumpSweep(reference,referenceSweep);
parameters=cell(2,1);
for i=1:2
    p=struct('id',"UPPER_Z_"+string(i),'quantity',"LENGTH",'scope',fsd.model.designScope('HARDPOINT',ids(i),'FL'), ...
        'type',"FREE",'binding',"HARDPOINT_Z",'value',xyz(i,3),'bounds',xyz(i,3)+[-.01,.01], ...
        'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Illustrative fixture +/-10mm envelope only");
    parameters{i}=fsd.model.createDesignParameter(p,'m');
end
fixed=fsd.model.createDesignConstraint(struct('id',"FIXED_UBJ",'type',"HARDPOINT_FIXED", ...
    'strength',"HARD",'scope',fsd.model.designScope('HARDPOINT','FL_UBJ','FL'), ...
    'position',xyz(3,:),'comparisonTolerance',0,'sourceNote',"Preserve original outboard joint"),'m');
box=fsd.model.createDesignConstraint(struct('id',"UPPER_BOX",'type',"AXIS_ALIGNED_BOX", ...
    'strength',"HARD",'scope',fsd.model.designScope('HARDPOINT',ids(1),'FL'), ...
    'bounds',[xyz(1,:)'-.01,xyz(1,:)'+.01],'sourceNote',"Nominal illustrative box, not CAD clearance"),'m');
base=struct('id',"CAMBER_TARGET",'metricId',"CAMBER",'sourceType',"BUMP",'sourceId',"BUMP_FL", ...
    'scope',fsd.model.designScope('CORNER','FL'),'type',"CURVE_TARGET",'strength',"SOFT", ...
    'independentVariable',"WHEEL_TRAVEL",'x',travel,'value',referenceAnalysis.camber_rad, ...
    'tolerance',1e-7,'normalizationScale',.01,'normalizationNote',"ASSUMED illustrative 0.01rad scale", ...
    'weight',1,'sourceNote',"ASSUMED objective from separately solved reachable reference, not vehicle performance");
camber=fsd.model.createDesignTarget(base,'rad','m'); base.id="TOE_TARGET"; base.metricId="TOE"; base.value=referenceAnalysis.toe_rad;
toe=fsd.model.createDesignTarget(base,'rad','m');
hard=rmfield(base,{'value','tolerance','weight'}); hard.id="TOE_LIMIT"; hard.strength="HARD";
hard.type="CURVE_BAND"; hard.lower=-.2; hard.upper=.2;
hard=fsd.model.createDesignTarget(hard,'rad','m');
specification=fsd.model.createDesignSpecification(struct('id',"INVERSE_DEMO",'parameters',{parameters}, ...
    'constraints',{{fixed;box}},'targets',fsd.model.createSuspensionDesignTargets({camber;toe;hard}),'compositeScore',true));
space=fsd.synthesis.createDesignSpace(seed,specification,struct('travel_m',travel));
options=struct('maxEvaluations',28,'maxIterations',12,'initialStep',.25,'minimumStep',1/128,'stopAtScore',1e-8);
result=fsd.synthesis.runInverseSearch(space,options); fsd.synthesis.validateSynthesisResult(result);
assert(isfinite(result.selectedIndex),'Illustrative reachable benchmark must produce an eligible scored candidate.');
first=result.search.records{1}; best=result.search.records{result.selectedIndex};
assert(best.score<first.score && ~isequaln(first.geometryIdentity,best.geometryIdentity),'Real HP change and score improvement required.');
comparison=fsd.synthesis.compareSynthesisCandidates(result,unique([1;result.selectedIndex]));
figures=gobjects(0); if showPlots, figures=fsd.synthesis.plotSynthesisResult(result,unique([1;result.selectedIndex])); end
output=struct('seed',seed,'specification',specification,'space',space,'result',result, ...
    'reference',reference,'referenceAnalysis',referenceAnalysis,'comparison',comparison,'figures',figures);
root=fileparts(fileparts(mfilename('fullpath')));
save(fullfile(root,'output','inverse-synthesis-example.mat'),'output');
fprintf('Inverse synthesis: %d unique evaluations, %d cached attempts, stop %s.\n',result.search.evaluationCount,result.search.cacheHitCount,result.search.stopReason);
fprintf('Explored eligible score: seed %.9g -> selected %.9g; HARD %s.\n',first.score,best.score,best.hardFeasibility);
hp=best.geometry.hardpoints;
disp(table(hp.ids,hp.xyz_m(:,1),hp.xyz_m(:,2),hp.xyz_m(:,3), ...
    'VariableNames',{'HardpointId','X_m','Y_m','Z_m'}));
for i=1:numel(result.search.records)
    e=result.search.records{i}; fprintf('  %d: %s score=%g reason=%s\n',i,e.classification,e.score,e.reason);
end
for i=1:numel(result.search.history)
    h=result.search.history{i};
    fprintf('  Attempt %d -> evaluation %d: accepted=%d cached=%d criterion=%s\n', ...
        h.attemptId,h.evaluationId,h.accepted,h.cacheHit,h.acceptanceCriterion);
end
fprintf('ASSUMED fixture only: no global optimality, continuous, CAD, rules or manufacturing certification.\n');
end
