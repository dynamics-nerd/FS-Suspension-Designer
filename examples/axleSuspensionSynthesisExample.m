function output = axleSuspensionSynthesisExample(showPlots,useSymmetry)
%AXLESUSPENSIONSYNTHESISEXAMPLE Reachable bilateral BUMP/ROLL design benchmark.
% Every dimension/bound/target/weight is ASSUMED software verification data,
% NOT a Formula Student setup recommendation. Expected curves are solved natively.
if nargin<1, showPlots=true; end
if nargin<2, useSymmetry=true; end
ids="FL_"+fsd.model.requiredHardpointRoles();
xyz=[-.12,-.38,.36;.10,-.42,.34;.03,-.60,.42;-.11,-.39,.14; ...
    .12,-.41,.16;-.02,-.60,.08;.04,-.39,.25;.05,-.57,.23;0,-.65,.25;0,-.65,0];
left=fsd.model.createDoubleWishboneGeometry('FL',ids,xyz,'m',[0,-1,0], ...
    struct('sourceKind',"ASSUMED",'sourceNote',"v0.13 reachable software fixture, not an FS design"));
% Explicit caller-side use of the existing reflection API: both seeds supplied.
right=fsd.geometry.reflectDoubleWishboneGeometry(left); seeds={left;right};
desired=left; desired.hardpoints.xyz_m(1:2,3)=xyz(1:2,3)+.005;
reference=fsd.model.createAxleGeometry(desired,fsd.geometry.reflectDoubleWishboneGeometry(desired));
plan=struct('leftBump',struct('travel_m',[-.01;0;.01]),'rightBump',struct('travel_m',[-.01;0;.01]), ...
    'roll',struct('angles_rad',[-.01;0;.01],'axleHeave_m',0));
rollSweep=fsd.kinematics.solveAxleRollSweep(reference,plan.roll.angles_rad,0,'rad','m');
rollAnalysis=fsd.analysis.analyzeAxleRollSweep(reference,rollSweep);
parameters=cell(0,1); constraints=cell(0,1); targets=cell(0,1); links=strings(2,2);
for j=1:2
    g=seeds{j}; ref=reference.leftGeometry; if j==2, ref=reference.rightGeometry; end
    for k=1:2
        id=g.cornerId+"_UPPER_Z_"+k; links(k,j)=id; value=g.hardpoints.xyz_m(k,3);
        p=struct('id',id,'quantity',"LENGTH",'scope',fsd.model.designScope('HARDPOINT',g.hardpoints.ids(k),g.cornerId), ...
            'type',"FREE",'binding',"HARDPOINT_Z",'value',value,'bounds',value+[-.01,.01], ...
            'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Test-only +/-10 mm closed search region");
        parameters{end+1,1}=fsd.model.createDesignParameter(p,'m'); %#ok<AGROW>
    end
    c=struct('id',g.cornerId+"_FIXED_UBJ",'scope',fsd.model.designScope('HARDPOINT',g.cornerId+"_UBJ",g.cornerId), ...
        'type',"HARDPOINT_FIXED",'strength',"HARD",'position',fsd.model.getPoint(g,g.cornerId+"_UBJ"), ...
        'comparisonTolerance',0,'sourceNote',"Explicit fixed outboard in software benchmark");
    constraints{end+1,1}=fsd.model.createDesignConstraint(c,'m'); %#ok<AGROW>
    sweep=fsd.kinematics.solveBumpSweep(ref,plan.leftBump.travel_m,'m'); a=fsd.analysis.analyzeBumpSweep(ref,sweep);
    for metric=["CAMBER","TOE"]
        value=a.camber_rad; if metric=="TOE", value=a.toe_rad; end
        t=target(g.cornerId+"_"+metric,metric,"BUMP_"+g.cornerId,"BUMP",fsd.model.designScope('CORNER',g.cornerId), ...
            "WHEEL_TRAVEL",plan.leftBump.travel_m,value,.01);
        targets{end+1,1}=fsd.model.createDesignTarget(t,'rad','m'); %#ok<AGROW>
    end
    t=target(g.cornerId+"_ROAD_CAMBER","ROAD_CAMBER","ROLL_FRONT","ROLL",fsd.model.designScope('CORNER',g.cornerId), ...
        "ROLL_ANGLE",plan.roll.angles_rad,rollAnalysis.roadCamber_rad(:,j),.01);
    t.conditions=struct('axleHeave_m',0);
    targets{end+1,1}=fsd.model.createDesignTarget(t,'rad','rad'); %#ok<AGROW>
end
if ~useSymmetry, links=strings(0,2); end
spec=fsd.model.createDesignSpecification(struct('id',"REACHABLE_AXLE",'parameters',{parameters}, ...
    'constraints',{constraints},'targets',fsd.model.createSuspensionDesignTargets(targets),'compositeScore',true));
space=fsd.synthesis.createAxleDesignSpace(left,right,spec,plan,links);
options=struct('maxEvaluations',40,'maxIterations',16,'initialStep',.25,'minimumStep',1/128,'stopAtScore',1e-8);
result=fsd.synthesis.runAxleInverseSearch(space,options);
fsd.synthesis.validateAxleSynthesisResult(result);
assert(isfinite(result.selectedIndex),'Reachable benchmark must retain a selected eligible axle.');
best=result.search.records{result.selectedIndex}; initial=result.search.records{1};
assert(best.score<initial.score,'Joint objective must improve.');
assert(~isequaln(best.axleIdentity.leftGeometryIdentity,space.seedIdentity.leftGeometryIdentity) && ...
    ~isequaln(best.axleIdentity.rightGeometryIdentity,space.seedIdentity.rightGeometryIdentity),'Both corners must change.');
% Independent post-selection repetition via public physical APIs, not synthesis.
directLeft=fsd.kinematics.solveBumpSweep(best.axle.leftGeometry,space.plan.leftBump.travel_m,'m',space.plan.leftBump.solverOptions);
directRight=fsd.kinematics.solveBumpSweep(best.axle.rightGeometry,space.plan.rightBump.travel_m,'m',space.plan.rightBump.solverOptions);
directRoll=fsd.kinematics.solveAxleRollSweep(best.axle,space.plan.roll.angles_rad,space.plan.roll.axleHeave_m,'rad','m',space.plan.roll.solverOptions);
figures=gobjects(0,1);
if showPlots, figures=fsd.synthesis.plotAxleSynthesisResult(result,[1;result.selectedIndex]); end
comparison=fsd.synthesis.compareAxleSynthesisCandidates(result,[1;result.selectedIndex]);
fprintf('AXLE %s: E%d, BUMP L%d/R%d, ROLL%d, score %.12g -> %.12g; %s\n', ...
    space.seedAxle.axleId,result.statistics.axleCandidateEvaluations,result.statistics.leftBumpSweeps, ...
    result.statistics.rightBumpSweeps,result.statistics.rollSweeps,initial.score,best.score,result.search.stopReason);
fprintf('ASSUMED verification data only; sampled/local; not a certified FS design.\n');
root=fileparts(fileparts(mfilename('fullpath'))); filename=fullfile(root,'output','axle-synthesis-example.mat');
save(filename,'result'); loaded=load(filename,'result'); fsd.synthesis.validateAxleSynthesisResult(loaded.result);
output=struct('space',space,'result',result,'reference',reference,'comparison',comparison, ...
    'directLeft',directLeft,'directRight',directRight,'directRoll',directRoll,'figures',figures,'matPath',string(filename));
end

function t = target(id,metric,sourceId,sourceType,scope,variable,x,value,scale)
t=struct('id',id,'metricId',metric,'sourceId',sourceId,'sourceType',sourceType,'scope',scope, ...
    'type',"CURVE_TARGET",'strength',"SOFT",'independentVariable',variable,'x',x,'value',value,'tolerance',1e-7, ...
    'normalizationScale',scale,'normalizationNote',"ASSUMED 0.01 rad software comparison scale", ...
    'weight',1,'sourceNote',"Independent reachable native reference; illustrative equal weights, not FS targets");
end
