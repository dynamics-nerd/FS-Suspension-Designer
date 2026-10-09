function result = staticLoadCore(vehicle, loadCase)
%STATICLOADCORE Algebraic vertical reactions; no kinematics or root solver.
timer = tic; d = vehicle.definitionSI; W = vehicle.totalMass_kg*d.gravity_mps2;
if ~isfinite(W), error("fsd:analysis:InvalidStaticLoads","Weight arithmetic overflow."); end
p = vehicle.contactPoints_m; cg = vehicle.cg_m; mode = loadCase.definitionSI.mode;
scale = max([d.wheelbase,d.frontTrack,d.rearTrack,max(abs(p(:)))]);
A = [ones(1,4);p(:,1)';p(:,2)']; b = W*[1;cg(1);cg(2)];
As = A./[1;scale;scale]; bs = b./[1;scale;scale];
forceTol = 1e-10*max(W,1); momentTol = forceTol*scale;
family = struct("matrixA",A,"rhs",b,"scaledMatrixA",As,"scale_m",scale, ...
    "rank",3,"degreeOfFreedom",1,"particular_N",nan(4,1),"nullDirection",nan(4,1), ...
    "lambdaInterval_N",[NaN,NaN],"cornerLoadBounds_N",nan(4,2), ...
    "crossweightBounds",[NaN,NaN],"feasible",false,"reciprocalCondition",NaN, ...
    "rawLambdaInterval_N",[NaN,NaN],"lambdaBoundaryBudget_N",NaN, ...
    "nullDirectionRoundoff",NaN,"loadRoundoff_N",NaN, ...
    "admissibleDimension",NaN,"intervalClassification","UNAVAILABLE", ...
    "endpointLoads_N",nan(4,2));
knownRows = isfinite(b);
family.degreeOfFreedom = 4-rank(As(knownRows,:));
family.knownConstraintRank = 4-family.degreeOfFreedom;
expected = [NaN;NaN];
% Axle sums remain identifiable from X alone for common longitudinal axle lines.
if isfinite(cg(1)) && abs(p(1,1)-p(2,1)) <= 1e-10*scale && ...
        abs(p(3,1)-p(4,1)) <= 1e-10*scale && p(3,1) > p(1,1)
    rear = W*(cg(1)-p(1,1))/(p(3,1)-p(1,1));
    expected = [W-rear;rear];
end
status = "INSUFFICIENT_CG_FOR_CORNER_LOADS"; normals = nan(4,1); candidate = normals;
normalKind = "UNAVAILABLE";
normalBudget = NaN; numericalClassification = "UNAVAILABLE";
if all(isfinite(cg(1:2)))
    [u,s,v] = svd(As); singular = diag(s(:,1:3));
    n = v(:,4); n = n/max(abs(n));
    first = find(abs(n) > 64*eps,1); if n(first) < 0, n = -n; end
    particular = v(:,1:3)*((u'*bs)./singular);
    algebra = staticLoadNumericalBudget(As,bs,particular);
    directionError = (norm(As*n)+algebra.gamma*singular(1)*norm(n))/ ...
        (singular(3)-algebra.gamma*singular(1));
    lo = -Inf; hi = Inf; possible = true; loError = 0; hiError = 0;
    for i = 1:4
        if abs(n(i)) <= directionError
            if particular(i) < -(algebra.loadRoundoff_N+ ...
                    (W+norm(particular))*directionError), possible = false; end
        elseif n(i) > 0
            bound = -particular(i)/n(i);
            if bound > lo
                lo = bound;
                loError = boundaryError(bound,n(i),algebra.loadRoundoff_N,directionError);
            end
        else
            bound = -particular(i)/n(i);
            if bound < hi
                hi = bound;
                hiError = boundaryError(bound,n(i),algebra.loadRoundoff_N,directionError);
            end
        end
    end
    family.particular_N = particular; family.nullDirection = n;
    family.rawLambdaInterval_N = [lo,hi];
    family.lambdaBoundaryBudget_N = loError+hiError;
    family.nullDirectionRoundoff = directionError;
    family.loadRoundoff_N = algebra.loadRoundoff_N;
    family.reciprocalCondition = singular(3)/singular(1);
    family.intervalClassification = "EMPTY";
    if possible && isfinite(lo) && isfinite(hi) && abs(hi-lo) <= loError+hiError
        % Deterministic numerical point, not a fourth independent equation.
        middle = lo+(hi-lo)/2;
        raw = particular+n*middle;
        pointBudget = algebra.loadRoundoff_N+abs(middle)*directionError+ ...
            algebra.gamma*norm(abs(particular)+abs(n*middle));
        [point,accepted] = admissibleLoads(As,bs,raw,pointBudget);
        if accepted
            lo = middle; hi = middle;
            family.endpointLoads_N = [point,point];
            family.feasible = true; family.admissibleDimension = 0;
            family.intervalClassification = "POINT_WITHIN_ROUNDOFF";
        end
    elseif possible && lo < hi
        rawEndpoints = particular+n*[lo,hi]; accepted = true;
        for endpoint = 1:2
            lambda = [lo,hi];
            endpointBudget = algebra.loadRoundoff_N+abs(lambda(endpoint))*directionError+ ...
                algebra.gamma*norm(abs(particular)+abs(n*lambda(endpoint)));
            [family.endpointLoads_N(:,endpoint),ok] = ...
                admissibleLoads(As,bs,rawEndpoints(:,endpoint),endpointBudget);
            accepted = accepted && ok;
        end
        family.feasible = accepted;
        if accepted
            family.admissibleDimension = 1; family.intervalClassification = "INTERVAL";
        end
    end
    family.lambdaInterval_N = [lo,hi];
    if family.feasible
        endpoints = family.endpointLoads_N;
        family.cornerLoadBounds_N = [min(endpoints,[],2),max(endpoints,[],2)];
        cw = [0,1,1,0]*endpoints/W; family.crossweightBounds = [min(cw),max(cw)];
        status = "CORNER_LOADS_UNDERDETERMINED";
        if abs(sum(n(1:2))) <= 128*eps
            expected = [sum(particular(1:2));sum(particular(3:4))];
        end
    else
        status = "NO_FEASIBLE_FOUR_CONTACT_LOADS";
    end
elseif all(isfinite(expected)) && any(expected < -forceTol)
    status = "NO_FEASIBLE_FOUR_CONTACT_LOADS";
end
if mode == "MEASURED_CORNER_LOADS"
    normals = loadCase.definitionSI.measuredCornerLoads_N;
    candidate = normals; normalKind = loadCase.definitionSI.sourceKind;
    status = "MEASURED_CG_NOT_FULLY_SPECIFIED";
elseif mode == "CROSSWEIGHT_SPECIFIED" && all(isfinite(cg(1:2)))
    C = [As;0,1,1,0]; rhs = [bs;W*loadCase.definitionSI.crossweightFraction];
    if rcond(C) <= sqrt(eps)
        status = "CROSSWEIGHT_NOT_UNIQUELY_RESOLVABLE";
    else
        candidate = C\rhs;
        closureBudget = staticLoadNumericalBudget(C,rhs,candidate);
        normalBudget = closureBudget.loadRoundoff_N;
        [acceptedLoads,accepted] = admissibleLoads(C,rhs,candidate,normalBudget);
        if ~accepted || ~family.feasible
            status = "INFEASIBLE_CROSSWEIGHT";
        else
            normals = acceptedLoads; normalKind = "DERIVED"; status = "CALCULATED_CORNER_LOADS";
            numericalClassification = "RESOLVED_NONNEGATIVE";
            if any(candidate <= normalBudget)
                numericalClassification = "NUMERICAL_BOUNDARY_COMPATIBLE";
            end
        end
    end
elseif mode == "ASSUMED_SYMMETRIC_BASELINE"
    compatible = isfinite(cg(2)) && abs(cg(2)) <= 1e-10*scale && ...
        all(isfinite(expected)) && all(expected >= 0) && ...
        abs(p(1,2)+p(2,2)) <= 1e-10*scale && abs(p(3,2)+p(4,2)) <= 1e-10*scale && ...
        abs(p(1,1)-p(2,1)) <= 1e-10*scale && abs(p(3,1)-p(4,1)) <= 1e-10*scale;
    if compatible
        normals = [expected(1);expected(1);expected(2);expected(2)]/2;
        candidate = normals; normalKind = "ASSUMED"; status = "ASSUMED_CORNER_LOADS";
    else
        status = "SYMMETRY_ASSUMPTION_INCOMPATIBLE";
    end
end
% Measurements, including tiny positive values, are NEVER adjusted.
if mode == "MEASURED_CORNER_LOADS"
    normalBudget = 0; numericalClassification = "ORIGINAL_MEASUREMENTS";
elseif mode == "ASSUMED_SYMMETRIC_BASELINE" && all(isfinite(normals))
    algebra = staticLoadNumericalBudget(As,bs,normals);
    normalBudget = algebra.loadRoundoff_N;
    [normals,accepted] = admissibleLoads(As,bs,normals,normalBudget);
    if ~accepted
        normals(:) = NaN; status = "SYMMETRY_ASSUMPTION_INCOMPATIBLE";
    else
        numericalClassification = "EXPLICIT_SYMMETRY_ASSUMPTION";
    end
end
residual = A*normals-b;
balanced = all(isfinite(residual)) && abs(residual(1)) <= forceTol && ...
    all(abs(residual(2:3)) <= momentTol);
limits = [forceTol;momentTol;momentTol];
knownBalanced = all(isfinite(residual(knownRows))) && all(abs(residual(knownRows)) <= limits(knownRows));
if mode == "MEASURED_CORNER_LOADS"
    if ~knownBalanced, status = "MEASURED_LOADS_INCONSISTENT";
    elseif balanced, status = "MEASURED_LOADS_CONSISTENT"; end
end
axle = expected; sides = [NaN;NaN]; diagonal = sides;
total = W; crossweight = NaN; complementary = NaN; measuredCW = NaN; inferredCG = nan(1,3);
if all(isfinite(normals))
    total = sum(normals); axle = [sum(normals(1:2));sum(normals(3:4))];
    sides = [sum(normals([1,3]));sum(normals([2,4]))];
    diagonal = [sum(normals([2,3]));sum(normals([1,4]))];
    if total > 0
        crossweight = diagonal(1)/W; complementary = diagonal(2)/W;
        measuredCW = diagonal(1)/total; % distinct, explicitly actual-sum-normalized metric
        inferredCG(1:2) = (p(:,1:2)'*normals/total)';
    end
end
supportCandidate = normals-vehicle.unsprungMass_kg*d.gravity_mps2;
supportRoundoff = 2*eps*(abs(normals)+abs(vehicle.unsprungMass_kg*d.gravity_mps2));
support = nan(4,1); supportStatus = repmat("INSUFFICIENT_LOCAL_SUPPORT_INFORMATION",4,1);
for i = 1:4
    if isfinite(supportCandidate(i))
        if supportCandidate(i) < -supportRoundoff(i)
            supportStatus(i) = "NEGATIVE_LOCAL_SUPPORT_DEMAND";
        elseif supportCandidate(i) < 0
            supportStatus(i) = "LOCAL_SUPPORT_NUMERICALLY_UNRESOLVED";
        elseif (mode ~= "MEASURED_CORNER_LOADS" || knownBalanced)
            support(i) = supportCandidate(i); supportStatus(i) = "REDUCED_SUPPORT_AVAILABLE";
        else
            supportStatus(i) = "INCONSISTENT_MEASURED_LOAD_CASE";
        end
    end
end
result = struct("schemaVersion","0.9.0","kind","StaticVehicleLoads", ...
    "vehicleIdentity",vehicle.identity,"loadCase",loadCase, ...
    "cornerIds",vehicle.cornerIds,"status",status,"totalNormalDemand_N",W, ...
    "totalNormalLoad_N",total,"expectedAxleLoads_N",expected, ...
    "frontAxleLoad_N",axle(1),"rearAxleLoad_N",axle(2), ...
    "leftLoad_N",sides(1),"rightLoad_N",sides(2),"diagonalLoads_N",diagonal, ...
    "crossweightFraction",crossweight,"complementaryDiagonalFraction",complementary, ...
    "measuredCrossweightActualSumFraction",measuredCW, ...
    "cornerLoads_N",normals,"candidateCornerLoads_N",candidate,"cornerLoadSourceKind",normalKind, ...
    "family",family,"inferredCG_m",inferredCG,"balanceResidual",residual, ...
    "forceTolerance_N",forceTol,"momentTolerance_Nm",momentTol, ...
    "normalRoundoffBudget_N",normalBudget,"numericalClassification",numericalClassification, ...
    "supportRoundoffBudget_N",supportRoundoff, ...
    "fourContactBalanceSatisfied",balanced,"knownBalanceSatisfied",knownBalanced,"supportForce_N",support, ...
    "candidateSupportForce_N",supportCandidate,"supportStatus",supportStatus, ...
    "supportAssumptions",["LUMPED_UNSPRUNG_MASS","IDEAL_LOCAL_VERTICAL_TRANSFER", ...
    "NO_ANTI_GEOMETRY","NO_AERO_OR_OTHER_EXTERNAL_LOADS"],"elapsedTime_s",toc(timer));
end

function error = boundaryError(lambda,direction,loadError,directionError)
% Ratio sensitivity, including the division's rounding, in N of lambda.
error = (loadError+abs(lambda)*directionError)/(abs(direction)-directionError)+ ...
    2*eps(abs(lambda));
end

function [loads,accepted] = admissibleLoads(matrix,rhs,raw,loadError)
% Only negative arithmetic residue may be corrected; recheck ORIGINAL rows,
% including the requested CW row. Positive small values are never snapped.
loads = raw; accepted = all(isfinite(raw)) && isfinite(loadError) && ...
    all(raw >= -loadError);
if ~accepted, loads(:) = NaN; return; end
loads(raw < 0) = 0;
gamma = 32*eps/(1-32*eps);
rowBudget = gamma*(abs(matrix)*abs(raw)+abs(rhs))+sum(abs(matrix),2)*loadError;
accepted = all(abs(matrix*loads-rhs) <= rowBudget);
if ~accepted, loads(:) = NaN; end
end
