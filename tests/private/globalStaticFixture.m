function [system, options, sources, tires, vehicle, loadCase] = globalStaticFixture(preload, mu, cg, kt, b)
%GLOBALSTATICFIXTURE Explicit ideal sampled paths, NOT solved suspension trajectories.
% Independent benchmark: M=200, g=10, ks=20000, MR=.5, R0=.25 (SI).
if nargin < 1, preload = repmat(.05,4,1); end
if nargin < 2, mu = zeros(4,1); end
if nargin < 3, cg = [1,0,.3]; end
if nargin < 4, kt = 100000; end
if nargin < 5, b = 0; end
[base,~,definition] = actuationFixture;
[~,~,~,mechanicalDefinition,units] = springDamperFixture;
sources = cell(4,1); tires = cell(4,1); corners = ["FL";"FR";"RL";"RR"];
z = (-.06:.002:.06)';
if b ~= 0, z = (-.0599:.0002:.0599)'; end % roots lie inside smooth polynomial pieces
for i = 1:4
    mirror = diag([1,1-2*mod(i+1,2),1]); shift = [2*floor((i-1)/2),0,0];
    xyz = base.hardpoints.xyz_m*mirror+shift;
    geometry = fsd.model.createDoubleWishboneGeometry(corners(i), ...
        corners(i)+"_"+fsd.model.requiredHardpointRoles(),xyz,"m",base.wheel.wheelAxis*mirror);
    d = definition; d.suspensionAttachment.point = d.suspensionAttachment.point*mirror+shift;
    d.rocker.axis.point = d.rocker.axis.point*mirror+shift;
    d.rocker.actuationRodPoint = d.rocker.actuationRodPoint*mirror+shift;
    d.rocker.damperPoint = d.rocker.damperPoint*mirror+shift;
    d.damper.chassisPoint = d.damper.chassisPoint*mirror+shift;
    actuation = fsd.model.createActuationGeometry(geometry,d,"m");
    md = mechanicalDefinition; md.spring.rate = 20000; md.spring.preloadCompression = preload(i);
    model = fsd.model.createSpringDamperModel(actuation,md,units);
    mechanical = fsd.analysis.analyzePrescribedSpringDamperPath(model,z,.5*z+b*z.^2,0, ...
        struct("length","m","velocity","m/s"));
    wc0 = fsd.model.getPoint(geometry,corners(i)+"_WHEEL_CENTER");
    wc = wc0+z*[0,0,1];
    sources{i} = struct("geometry",geometry,"actuation",actuation,"springDamper",model, ...
        "mechanical",mechanical,"pathKind","IDEAL_PRESCRIBED_3D", ...
        "idealWheelCenterPath_m",wc,"sourceKind","ASSUMED", ...
        "sourceNote","Independent vertical translation benchmark, no mechanism feasibility claim");
    tires{i} = fsd.model.createVerticalTireModel(struct("cornerId",corners(i), ...
        "modelType","LINEAR_VERTICAL_UNILATERAL","stiffness",kt,"unloadedRadius",.25, ...
        "sourceKind","ASSUMED","sourceNote","Independent benchmark"), ...
        struct("length","m","stiffness","N/m"));
end
[~,vd,vu] = vehicleFixture; vd.totalMass = 200; vd.cg = cg; vd.unsprungMass = mu;
vd.frontTrack = 1.3; vd.rearTrack = 1.3;
vehicle = fsd.model.createVehicleParameters(vd,vu);
loadCase = fsd.model.createVehicleLoadCase(vehicle, ...
    struct("mode","UNDERDETERMINED","sourceKind","KNOWN"));
system = fsd.model.createGlobalStaticSystem(vehicle,loadCase,sources,tires, ...
    struct("massApproximation","KNOWN_UNSPRUNG_MASSES", ...
    "unsprungPositionAssumption","UNSPRUNG_MASS_AT_WHEEL_CENTER", ...
    "rideHeightPointsBody_m",[1,0,.1],"rideHeightPointIds","TEST_REFERENCE"));
options = struct("bounds",[-.1,.1;-.15,.15;-.15,.15;repmat([-.05,.05],4,1)], ...
    "coordinateScales",[.02;.05;.05;repmat(.02,4,1)], ...
    "forceTolerance_N",1e-6,"momentTolerance_Nm",1e-7,"positionTolerance_m",1e-9, ...
    "angleTolerance_rad",1e-9,"stabilityTolerance_J",1e-8);
end
