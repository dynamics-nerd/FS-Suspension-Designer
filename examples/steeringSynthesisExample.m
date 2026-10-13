function output = steeringSynthesisExample(showPlots)
%STEERINGSYNTHESISEXAMPLE Reachable native search and explicit zero-target tradeoff.
% All geometry/bounds/references/weights/targets are ASSUMED verification data,
% NOT Formula Student setup recommendations.
if nargin<1, showPlots=true; end
xyz=[-.12,-.38,.36;.10,-.42,.34;.03,-.60,.42;-.11,-.39,.14; ...
    .12,-.41,.16;-.02,-.60,.08;.04,-.39,.25;.05,-.57,.23;0,-.65,.25;0,-.65,0];
left=fsd.model.createDoubleWishboneGeometry('FL',"FL_"+fsd.model.requiredHardpointRoles(), ...
    xyz,'m',[0,-1,0],struct('sourceKind',"ASSUMED",'sourceNote',"v0.14 software mechanism only"));
right=fsd.geometry.reflectDoubleWishboneGeometry(left);
steering=fsd.model.createSteeringSystem(fsd.model.createAxleGeometry(left,right),1.6,'m');
desired=left; desired.hardpoints.xyz_m(8,1)=.055;
reference=fsd.model.createSteeringSystem(fsd.model.createAxleGeometry(desired, ...
    fsd.geometry.reflectDoubleWishboneGeometry(desired)),1.6,'m');
plan=struct('leftBump',struct('travel_m',[-.01;0;.01]), ...
    'rightBump',struct('travel_m',[-.01;0;.01]),'referenceRackTravel_m',0, ...
    'rack',struct('travel_m',[-.006;-.003;0;.003;.006], ...
    'wheelTravel_m',[0,0],'travelLimits_m',[-.01,.01]));
% Expected physics generated through public APIs, independently of synthesis.
referenceRack=fsd.kinematics.solveRackSweep(reference,plan.rack.travel_m,[0,0],'m');
referenceAnalysis=fsd.analysis.analyzeRackSweep(reference,referenceRack);
parameters=cell(0,1); constraints=cell(0,1); targets=cell(0,1);
geometries={left;right};
refGeometries={reference.frontAxleGeometry.leftGeometry;reference.frontAxleGeometry.rightGeometry};
for j=1:2
    g=geometries{j}; hp=g.cornerId+"_TIE_ROD_OUTBOARD";
    parameters{end+1,1}=fsd.model.createDesignParameter(struct('id',g.cornerId+"_PICKUP_X",'quantity',"LENGTH", ...
        'scope',fsd.model.designScope('HARDPOINT',hp,g.cornerId),'type',"FREE",'binding',"HARDPOINT_X", ...
        'value',.05,'bounds',[.04,.06],'availability',"ASSUMED",'sourceKind',"ASSUMED", ...
        'sourceNote',"Illustrative +/-10 mm coordinate box"),'m'); %#ok<AGROW>
    for role=["UBJ","TIE_ROD_INBOARD"]
        constraints{end+1,1}=fsd.model.createDesignConstraint(struct('id',g.cornerId+"_FIXED_"+role, ...
            'scope',fsd.model.designScope('HARDPOINT',g.cornerId+"_"+role,g.cornerId), ...
            'type',"HARDPOINT_FIXED",'strength',"HARD",'position',fsd.model.getPoint(g,g.cornerId+"_"+role), ...
            'comparisonTolerance',0,'sourceNote',"Explicit fixed nominal joint"),'m'); %#ok<AGROW>
    end
    point=fsd.model.getPoint(g,hp);
    constraints{end+1,1}=fsd.model.createDesignConstraint(struct('id',g.cornerId+"_PICKUP_BOX", ...
        'scope',fsd.model.designScope('HARDPOINT',hp,g.cornerId),'type',"AXIS_ALIGNED_BOX",'strength',"HARD", ...
        'bounds',[.04,.06;point(2),point(2);point(3),point(3)], ...
        'sourceNote',"Nominal software box, NOT collision detection"),'m'); %#ok<AGROW>
    rg=refGeometries{j}; b=fsd.kinematics.solveBumpSweep(rg,plan.leftBump.travel_m,'m');
    a=fsd.analysis.analyzeBumpSweep(rg,b);
    for metric=["BUMP_STEER","TOE"]
        values=a.bumpSteer_rad; weight=3;
        if metric=="TOE", values=a.toe_rad; weight=1; end
        d=target(g.cornerId+"_"+metric,metric,"BUMP_"+g.cornerId,"BUMP", ...
            fsd.model.designScope('CORNER',g.cornerId),"WHEEL_TRAVEL",plan.leftBump.travel_m,values,.01,weight);
        targets{end+1,1}=fsd.model.createDesignTarget(d,'rad','m'); %#ok<AGROW>
    end
    side="left"; if j==2, side="right"; end
    for metric=["ROAD_WHEEL_ANGLE","TOE"]
        field="roadWheelAngle_rad"; if metric=="TOE", field="toe_rad"; end
        values=arrayfun(@(s) s.(side).(field),referenceAnalysis.states);
        d=target(g.cornerId+"_RACK_"+metric,metric,"RACK_FRONT","RACK", ...
            fsd.model.designScope('CORNER',g.cornerId),"RACK_TRAVEL",plan.rack.travel_m,values,.01,.5);
        d.conditions=struct('wheelTravel_m',[0,0]);
        targets{end+1,1}=fsd.model.createDesignTarget(d,'rad','m'); %#ok<AGROW>
    end
end
for direction=[-1,1]
    indices=[1;2]; label="NEGATIVE_RACK"; if direction>0, indices=[4;5]; label="POSITIVE_RACK"; end
    d=target("ACK_"+label,"ACKERMANN_ANGLE_ERROR","RACK_FRONT","RACK", ...
        fsd.model.designScope('AXLE','FRONT'),"RACK_TRAVEL",plan.rack.travel_m(indices), ...
        referenceAnalysis.ackermannAngleError_rad(indices),.001,2);
    d.conditions=struct('wheelTravel_m',[0,0]);
    targets{end+1,1}=fsd.model.createDesignTarget(d,'rad','m'); %#ok<AGROW>
end
spec=fsd.model.createDesignSpecification(struct('id',"REACHABLE_STEERING",'parameters',{parameters}, ...
    'constraints',{constraints},'targets',fsd.model.createSuspensionDesignTargets(targets),'compositeScore',true));
space=fsd.synthesis.createSteeringDesignSpace(left,right,steering,spec,plan,["FL_PICKUP_X","FR_PICKUP_X"]);
options=struct('maxEvaluations',9,'maxIterations',4,'initialStep',.25,'minimumStep',1/128,'stopAtScore',1e-8);
result=fsd.synthesis.runSteeringInverseSearch(space,options);
fsd.synthesis.validateSteeringSynthesisResult(result);
assert(isfinite(result.selectedIndex),'Reachable benchmark requires a scored eligible candidate.');
first=result.search.records{1}; best=result.search.records{result.selectedIndex};
assert(best.score<first.score && ~isequaln(best.steeringIdentity,first.steeringIdentity));
assert(~isequaln(best.axleIdentity.leftGeometryIdentity,first.axleIdentity.leftGeometryIdentity) && ...
    ~isequaln(best.axleIdentity.rightGeometryIdentity,first.axleIdentity.rightGeometryIdentity));
directLeft=fsd.kinematics.solveBumpSweep(best.axle.leftGeometry,space.plan.leftBump.travel_m,'m',space.plan.leftBump.solverOptions);
directRight=fsd.kinematics.solveBumpSweep(best.axle.rightGeometry,space.plan.rightBump.travel_m,'m',space.plan.rightBump.solverOptions);
directRack=fsd.kinematics.solveRackSweep(best.steering,space.plan.rack.travel_m, ...
    space.plan.rack.wheelTravel_m,'m',space.plan.rack.solverOptions);
comparison=fsd.synthesis.compareSteeringSynthesisCandidates(result,(1:numel(result.search.records))');
% SECOND explicitly labelled specification: zero bump steer and ideal Ackermann.
% Same fresh native evidence, not another solve/search or the reachable objective.
tradeoffDefinition=spec.definitionSI; tradeoffDefinition.id="ZERO_STEER_TRADEOFF";
tradeoffTargets=targets(cellfun(@(t) ismember(t.definitionSI.metricId,["BUMP_STEER","ACKERMANN_ANGLE_ERROR"]),targets));
for j=1:numel(tradeoffTargets)
    d=tradeoffTargets{j}.definitionSI; d.value=zeros(size(d.value));
    d.sourceNote="Zero-metric tradeoff diagnostic, NOT the reachable search objective";
    tradeoffTargets{j}=fsd.model.createDesignTarget(d,'rad','m');
end
tradeoffDefinition.targets=fsd.model.createSuspensionDesignTargets(tradeoffTargets);
tradeoffSpecification=fsd.model.createDesignSpecification(tradeoffDefinition);
candidates=cellfun(@(e) e.candidate,result.search.records,'UniformOutput',false);
tradeoffComparison=fsd.analysis.compareDesignCandidates(tradeoffSpecification,candidates);
tradeoffValues=zeros(numel(candidates),4);
for j=1:numel(candidates)
    tradeoffValues(j,:)=cellfun(@(q) q.rmsNormalizedError,tradeoffComparison.assessments{j}.targetAssessments)';
end
figures=gobjects(0,1);
if showPlots
    figures=fsd.synthesis.plotSteeringSynthesisResult(result,(1:numel(candidates))');
    diagnostic=fsd.analysis.plotDesignTargetEvaluation(tradeoffSpecification,candidates);
    for j=1:numel(diagnostic)
        diagnostic(j).Name="Zero-metric tradeoff: "+string(diagnostic(j).Name);
        diagnostic(j).Position=[50,50,1300,850];
        set(findall(diagnostic(j),'Type','legend'),'Location','eastoutside');
    end
    figures=[figures;diagnostic];
end
root=fileparts(fileparts(mfilename('fullpath'))); filename=fullfile(root,'output','steering-synthesis-example.mat');
save(filename,'result','tradeoffSpecification','tradeoffComparison');
loaded=load(filename,'result'); fsd.synthesis.validateSteeringSynthesisResult(loaded.result);
fprintf('STEERING: E%d, BUMP L%d/R%d, RACK%d, ROLL%d, score %.12g -> %.12g; %s\n', ...
    result.search.evaluationCount,result.statistics.leftBumpSweeps,result.statistics.rightBumpSweeps, ...
    result.statistics.rackSweeps,result.statistics.rollSweeps,first.score,best.score,result.search.stopReason);
fprintf('ASSUMED sampled/local verification only; zero-metric tradeoff is a separate specification.\n');
output=struct('space',space,'result',result,'reference',reference,'referenceRack',referenceRack, ...
    'directLeft',directLeft,'directRight',directRight,'directRack',directRack,'comparison',comparison, ...
    'tradeoffSpecification',tradeoffSpecification,'tradeoffComparison',tradeoffComparison, ...
    'tradeoffValues',tradeoffValues,'figures',figures,'matPath',string(filename),'additionalPhysicalSweeps',6);
end

function d = target(id,metric,sourceId,family,scope,variable,x,value,scale,weight)
d=struct('id',id,'metricId',metric,'sourceId',sourceId,'sourceType',family,'scope',scope, ...
    'type',"CURVE_TARGET",'strength',"SOFT",'independentVariable',variable,'x',x,'value',value, ...
    'tolerance',1e-7,'normalizationScale',scale,'normalizationNote',"ASSUMED software comparison scale "+scale+" rad", ...
    'weight',weight,'sourceNote',"Independent reachable native reference; explicit unequal verification weights");
end
