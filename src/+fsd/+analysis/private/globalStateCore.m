function [state, timings] = globalStateCore(p, q)
%GLOBALSTATECORE Single canonical energy, analytic gradient/Hessian; no validation/solves.
timer = tic; energyTime = 0; gradientTime = 0;
s = p.system; v = s.vehicle; g = v.definitionSI.gravity_mps2;
mu = s.unsprungMass_kg; M = v.totalMass_kg; Ms = p.sprungMass_kg;
[R,D,DD] = globalRotation(q(2),q(3)); translation = [0;0;q(1)];
cg = R*p.sprungCgBody_m'+translation;
[cgFirst,cgSecond] = heightDerivatives(p.sprungCgBody_m',zeros(3,1),zeros(3,1),0,R,D,DD);
U = Ms*g*cg(3); gravityEnergy = U; springEnergy = 0; tireEnergy = 0;
gradient = Ms*g*cgFirst; H = Ms*g*cgSecond;
wc = nan(4,3); corners = cell(4,1); feasible = true; smooth = true;
for i = 1:4
    model = s.sources{i}.springDamper; value = globalPathValue(p.paths{i},q(i+3));
    corner = struct("cornerId",s.cornerIds(i),"wheelTravel_m",q(i+3), ...
        "pathStatus",value.status,"pathSegmentIndex",value.segmentIndex,"wheelCenterWorld_m",nan(1,3), ...
        "damperLength_m",NaN,"damperCompression_m",NaN,"motionRatio",NaN, ...
        "spring",struct(),"bounds",struct(),"tire",struct(), ...
        "springWheelResistance_N",NaN,"damperAxialResistance_N",0, ...
        "motionRatioDifference",NaN,"curvatureResolved",value.curvatureResolved);
    if ~value.available
        feasible = false; smooth = false; corners{i} = corner; continue;
    end
    world = R*value.p+translation; wc(i,:) = world';
    L = model.derivedStaticGeometry.damperStaticLength_m-value.c;
    seats = L+model.derivedStaticGeometry.springSeatOffset_m;
    spring = springLaw(model.spring,value.c); bounds = mechanicalBounds(model,L,seats);
    tire = verticalTireResponse(s.tires{i},world(3),s.options.roadHeight_m);
    corner.wheelCenterWorld_m = world'; corner.damperLength_m = L;
    corner.damperCompression_m = value.c; corner.motionRatio = value.mr;
    corner.spring = spring; corner.bounds = bounds; corner.tire = tire;
    corner.motionRatioDifference = value.motionRatioDifference;
    corner.springWheelResistance_N = spring.springAxialForce_N*value.mr;
    if ~bounds.feasibleRelativeToProvidedLimits || tire.loadedRadius_m <= 0
        corner.pathStatus = "MECHANICAL_LIMIT_OR_COLLAPSED_RADIUS";
        corner.spring.springAxialForce_N = NaN; corner.spring.springStoredEnergy_J = NaN;
        corner.springWheelResistance_N = NaN; feasible = false;
    end
    smooth = smooth && value.curvatureResolved && ...
        ~any(tire.contactStatus == ["CONTACT_TRANSITION","CONTACT_NUMERICALLY_UNRESOLVED"]) && ...
        spring.springStatus ~= "SPRING_ENGAGEMENT_TRANSITION" && ...
        bounds.springSolidStatus ~= "COIL_BIND_LIMIT";
    part = tic;
    gravityEnergy = gravityEnergy+mu(i)*g*world(3);
    springEnergy = springEnergy+spring.springStoredEnergy_J;
    tireEnergy = tireEnergy+tire.tireStoredEnergy_J;
    U = gravityEnergy+springEnergy+tireEnergy;
    energyTime = energyTime+toc(part); part = tic;
    [dZ,ddZ] = heightDerivatives(value.p,value.dp,value.ddp,i+3,R,D,DD);
    balance = mu(i)*g-tire.normalForce_N;
    gradient = gradient+balance*dZ;
    gradient(i+3) = gradient(i+3)+corner.springWheelResistance_N;
    H = H+balance*ddZ;
    if tire.rawTireCompression_m > 0
        H = H+s.tires{i}.stiffness_N_per_m*(dZ*dZ');
    end
    if spring.springStatus == "SPRING_COMPRESSED"
        H(i+3,i+3) = H(i+3,i+3)+model.spring.rate_N_per_m*value.mr^2+ ...
            spring.springAxialForce_N*value.c2;
    end
    gradientTime = gradientTime+toc(part);
    corners{i} = corner;
end
normal = nan(4,1);
for i = 1:4
    if ~isempty(fieldnames(corners{i}.tire)), normal(i) = corners{i}.tire.normalForce_N; end
end
force = sum(normal)-M*g;
actualCG = (Ms*cg'+mu'*wc)/M;
moment = [sum(wc(:,2).*(normal-mu*g))-Ms*g*cg(2); ...
    -sum(wc(:,1).*(normal-mu*g))+Ms*g*cg(1);0];
if ~feasible || any(~isfinite([U;gradient]))
    U = NaN; gradient(:) = NaN; H(:) = NaN; smooth = false;
    gravityEnergy = NaN; springEnergy = NaN; tireEnergy = NaN;
end
heights = (R*s.options.rideHeightPointsBody_m')'+translation';
cw = NaN;
if sum(normal) > 0, cw = (normal(2)+normal(3))/sum(normal); end
state = struct("schemaVersion","0.10.0","kind","GlobalStaticState", ...
    "systemIdentity",p.identity,"q",q,"heave_m",q(1),"pitch_rad",q(2),"roll_rad",q(3), ...
    "rotationMatrix",R,"approximation",p.approximation,"feasible",feasible, ...
    "status","EVALUATED_NOT_SOLVED","corners",{corners},"potentialEnergy_J",U, ...
    "gravityEnergy_J",gravityEnergy,"springEnergy_J",springEnergy,"tireEnergy_J",tireEnergy, ...
    "residual",gradient,"candidateHessian",H,"bilateralHessianAvailable",smooth, ...
    "weight_N",M*g,"normalForces_N",normal,"axleLoads_N",[sum(normal(1:2));sum(normal(3:4))], ...
    "sideLoads_N",[sum(normal([1,3]));sum(normal([2,4]))],"crossweightActualSumFraction",cw, ...
    "sprungCgWorld_m",cg',"totalCgWorld_m",actualCG,"sprungMass_kg",Ms, ...
    "unsprungMass_kg",mu,"worldForceResidual_N",force,"worldMomentResidual_Nm",moment, ...
    "rideHeightPointIds",s.options.rideHeightPointIds, ...
    "rideHeightPointsWorld_m",heights,"rideHeights_m",heights(:,3)-s.options.roadHeight_m, ...
    "comparisonV09",struct("reference",p.referenceLoadsV09, ...
    "predictedMinusReference_N",normal-p.referenceLoadsV09.cornerLoads_N, ...
    "referenceNotImposed",true));
timings = struct("stateEvaluationTime_s",toc(timer),"energyAssemblyTime_s",energyTime, ...
    "gradientAndHessianAssemblyTime_s",gradientTime);
end

function [first, second] = heightDerivatives(point, dp, ddp, index, R, D, DD)
first = zeros(7,1); second = zeros(7); first(1) = 1;
for j = 1:2
    a = D(:,:,j)*point; first(j+1) = a(3);
end
a = DD(:,:,1)*point; second(2,2) = a(3);
a = DD(:,:,2)*point; second(2,3) = a(3); second(3,2) = a(3);
a = DD(:,:,3)*point; second(3,3) = a(3);
if index > 0
    a = R*dp; first(index) = a(3);
    a = R*ddp; second(index,index) = a(3);
    for j = 1:2
        a = D(:,:,j)*dp; second(j+1,index) = a(3); second(index,j+1) = a(3);
    end
end
end
