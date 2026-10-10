function output = designTargetEvaluationExample(showPlots)
%DESIGNTARGETEVALUATIONEXAMPLE Progressive specification and two solved candidates.
% ALL numbers are illustrative/ASSUMED, NOT recommended Formula Student targets.
if nargin < 1, showPlots = true; end
vehicleScope = fsd.model.designScope("VEHICLE","VEHICLE");
hpScope = fsd.model.designScope("HARDPOINT","FL_UBJ","FL");
common = struct("quantity","LENGTH","scope",vehicleScope,"sourceNote","Illustrative supplied datum, not a real car measurement");
p = common; p.id = "WHEELBASE"; p.type = "KNOWN"; p.value = 2;
p.availability = "KNOWN"; p.sourceKind = "KNOWN"; p.binding = "VEHICLE_WHEELBASE";
parameters = {fsd.model.createDesignParameter(p,"m")};
p = common; p.id = "FRONT_TRACK_RANGE"; p.type = "RANGE"; p.bounds = [1.2,1.4]; p.binding = "VEHICLE_FRONT_TRACK";
parameters{end+1,1} = fsd.model.createDesignParameter(p,"m");
p = common; p.id = "UBJ_X_FIXED"; p.type = "FIXED"; p.scope = hpScope; p.binding = "HARDPOINT_X";
p.value = 0; p.availability = "KNOWN"; p.sourceKind = "KNOWN"; p.comparisonTolerance = 0;
parameters{end+1,1} = fsd.model.createDesignParameter(p,"m");
p = struct("id","MASS_ESTIMATE","quantity","MASS","scope",vehicleScope,"type","ASSUMED", ...
    "value",200,"availability","ASSUMED","sourceKind","ASSUMED","sourceNote","Illustrative mass assumption");
parameters{end+1,1} = fsd.model.createDesignParameter(p,"kg");
p = struct("id","SPRING_RATE_FREE","quantity","STIFFNESS","scope", ...
    fsd.model.designScope("COMPONENT","MECH_FL","FL"),"type","FREE","binding","SPRING_RATE");
parameters{end+1,1} = fsd.model.createDesignParameter(p,"N/m"); % bounds intentionally not supplied
p = struct("id","CG_X_UNKNOWN","quantity","LENGTH","scope",vehicleScope,"type","KNOWN");
parameters{end+1,1} = fsd.model.createDesignParameter(p,"m"); % [] is unknown, never zero
base = struct("id","CAMBER_FL","metricId","CAMBER","sourceId","BUMP_FL","sourceType","BUMP", ...
    "scope",fsd.model.designScope("CORNER","FL"),"type","CURVE_TARGET","strength","SOFT", ...
    "independentVariable","WHEEL_TRAVEL","x",[-.02;.02],"value",-.02,"tolerance",.001, ...
    "normalizationScale",.02,"normalizationNote","Illustrative angle scale chosen by this example", ...
    "sourceNote","ASSUMED example objective only");
targets = {fsd.model.createDesignTarget(base,"rad","m")};
d = base; d.id = "TOE_FL"; d.metricId = "TOE"; d.type = "CURVE_BAND";
d = rmfield(d,["value","tolerance"]); d.lower = -.005; d.upper = .005;
d.normalizationScale = .005; targets{end+1,1} = fsd.model.createDesignTarget(d,"rad","m");
d = base; d.id = "MR_FL"; d.metricId = "MOTION_RATIO"; d.sourceId = "MECH_FL";
d.sourceType = "MECHANICAL"; d.value = .5; d.tolerance = .05; d.normalizationScale = .05;
d.normalizationNote = "Illustrative dimensionless MR scale";
targets{end+1,1} = fsd.model.createDesignTarget(d,"1","m");
d = struct("id","ACKERMANN_MISSING","metricId","ACKERMANN_ANGLE_ERROR", ...
    "sourceId","FRONT_RACK","sourceType","RACK","scope",fsd.model.designScope("AXLE","FRONT"), ...
    "type","POINT_TARGET","strength","HARD","independentVariable","RACK_TRAVEL", ...
    "x",.005,"value",0,"tolerance",.01,"conditions",struct("wheelTravel_m",[0,0]), ...
    "sourceNote","Illustrative objective; steering source intentionally absent");
targets{end+1,1} = fsd.model.createDesignTarget(d,"rad","m");
box = fsd.model.createDesignConstraint(struct("id","UBJ_BOX","scope",hpScope, ...
    "type","AXIS_ALIGNED_BOX","strength","HARD","bounds",[-.005,.005;-.605,-.595;.395,.405], ...
    "sourceNote","Illustrative admissible region; not a collision certificate"),"m");
specification = fsd.model.createDesignSpecification(struct("id","ILLUSTRATIVE_REQUIREMENTS", ...
    "parameters",{parameters},"constraints",{{box}},"targets",fsd.model.createSuspensionDesignTargets(targets), ...
    "metadata",struct("eventPriority","BALANCED","displayName","Illustrative progressive design")));
% Source generation is explicit and OUTSIDE the evaluator. No target moves a point.
candidates = {solvedCandidate("DESIGN_A",0,[0,-1,0]); ...
    solvedCandidate("DESIGN_B",.01,[-tan(.01),-1,tan(.02)])};
comparison = fsd.analysis.compareDesignCandidates(specification,candidates);
for i = 1:numel(candidates)
    a = comparison.assessments{i};
    fprintf("%s: %s\n",a.candidateId,a.hardFeasibility);
    disp(fsd.analysis.designAssessmentTable(a,specification,candidates{i}));
end
fprintf("Unknown inputs: %s\n",join(comparison.assessments{1}.readiness.unknownParameters,", "));
fprintf("No automatic winner. A has better toe; B has better camber but violates UBJ constraints.\n");
fprintf("ASSUMED examples only; samples, no continuous/packaging/rules/performance certification.\n");
figures = gobjects(0); if showPlots, figures = fsd.analysis.plotDesignTargetEvaluation(specification,candidates); end
output = struct("specification",specification,"candidates",{candidates}, ...
    "comparison",comparison,"figures",figures);
end

function candidate = solvedCandidate(id, xShift, axis)
xyz = [-.1,-.3,.4;.1,-.3,.4;0,-.6,.4;-.1,-.3,.1;.1,-.3,.1;0,-.6,.1; ...
    .05,-.3,.25;.05,-.6,.25;0,-.65,.25;0,-.65,0]+[xShift,0,0];
geometry = fsd.model.createDoubleWishboneGeometry("FL","FL_"+fsd.model.requiredHardpointRoles(), ...
    xyz,"m",axis/norm(axis),struct("sourceKind","ASSUMED","sourceNote","Illustrative parallel-arm geometry"));
shift = [xShift,0,0];
ad = struct("actuationType","PUSHROD","suspensionAttachment",struct("body","UPRIGHT","point",[0,.15,.1]+shift), ...
    "rocker",struct("orientationMode","YZ_PLANE","axis",struct("point",shift), ...
    "actuationRodPoint",[0,.1,0]+shift,"damperPoint",[0,0,.1]+shift), ...
    "damper",struct("chassisPoint",[.12,-.08,.16]+shift));
actuation = fsd.model.createActuationGeometry(geometry,ad,"m");
md = struct("configuration","COILOVER","spring",struct("modelType","LINEAR_COMPRESSION", ...
    "rate",30000,"freeLength",.2,"preloadCompression",.02),"damper", ...
    struct("modelType","LINEAR_ASYMMETRIC","compressionCoefficient",1500,"reboundCoefficient",2500), ...
    "metadata",struct("sourceKind","ASSUMED","sourceNote","Illustrative mechanical inputs"));
model = fsd.model.createSpringDamperModel(actuation,md,struct("length","m","springRate","N/m", ...
    "dampingCoefficient","N*s/m","velocity","m/s"));
bump = fsd.kinematics.solveBumpSweep(geometry,(-.02:.005:.02)',"m");
analysis = fsd.analysis.analyzeBumpSweep(geometry,bump);
sweep = fsd.kinematics.solveActuationSweep(actuation,bump);
aa = fsd.analysis.analyzeActuationSweep(actuation,sweep);
mechanical = fsd.analysis.analyzeSpringDamperSweep(model,actuation,sweep,aa,0,"m/s");
sources = {struct("id","BUMP_FL","type","BUMP","model",geometry,"sweep",bump,"result",analysis); ...
    struct("id","MECH_FL","type","MECHANICAL","model",model,"auxiliary",actuation,"result",mechanical)};
candidate = fsd.model.createDesignCandidate(struct("id",id,"geometries",{{geometry}},"sources",{sources}));
end
