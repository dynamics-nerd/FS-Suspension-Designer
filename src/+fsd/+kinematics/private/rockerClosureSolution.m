function solution = rockerClosureSolution(A_m2, B_m2, D_m2, ...
    coefficientScale_m2, referenceAngle_rad)
%ROCKERCLOSURESOLUTION Classify and solve A*cos(theta)+B*sin(theta)=D.

R_m2 = hypot(A_m2, B_m2);
tolerance_m2 = 64 * eps(coefficientScale_m2);
solution = struct( ...
    "constraintCase", "", ...
    "R_m2", R_m2, ...
    "coefficientTolerance_m2", tolerance_m2, ...
    "alpha_rad", NaN, ...
    "acosRatio", NaN, ...
    "candidateAngles_rad", NaN(1,0), ...
    "selectedCandidateIndex", NaN, ...
    "selectedAngle_rad", NaN, ...
    "derivativeMagnitude_m2", NaN, ...
    "conditioning", NaN, ...
    "isIllConditioned", false);

if R_m2 <= tolerance_m2
    if abs(D_m2) <= tolerance_m2
        solution.constraintCase = "ALL_ANGLES";
    else
        solution.constraintCase = "NO_INTERSECTION_R_ZERO";
    end
    return
end
if abs(D_m2) > R_m2 + tolerance_m2
    solution.constraintCase = "NO_INTERSECTION";
    return
end

solution.alpha_rad = atan2(B_m2, A_m2);
if abs(abs(D_m2) - R_m2) <= tolerance_m2
    solution.constraintCase = "TANGENT";
    solution.acosRatio = sign(D_m2);
    if solution.acosRatio == 0
        solution.acosRatio = 1;
    end
    baseCandidate_rad = solution.alpha_rad + acos(solution.acosRatio);
    candidates_rad = nearestEquivalent(baseCandidate_rad, referenceAngle_rad);
    solution.candidateAngles_rad = candidates_rad;
    solution.selectedCandidateIndex = 1;
    solution.selectedAngle_rad = candidates_rad;
    solution.derivativeMagnitude_m2 = 0;
    solution.conditioning = 0;
    solution.isIllConditioned = true;
    return
end

ratio = D_m2 / R_m2;
solution.constraintCase = "TWO_SOLUTIONS";
solution.acosRatio = ratio;
offset_rad = acos(ratio);
baseCandidates_rad = [solution.alpha_rad + offset_rad, ...
    solution.alpha_rad - offset_rad];
candidates_rad = nearestEquivalent(baseCandidates_rad, referenceAngle_rad);
[~, selectedIndex] = min(abs(candidates_rad-referenceAngle_rad));
theta_rad = candidates_rad(selectedIndex);
derivativeMagnitude_m2 = abs( ...
    -A_m2*sin(theta_rad) + B_m2*cos(theta_rad));
solution.candidateAngles_rad = candidates_rad;
solution.selectedCandidateIndex = selectedIndex;
solution.selectedAngle_rad = theta_rad;
solution.derivativeMagnitude_m2 = derivativeMagnitude_m2;
solution.conditioning = derivativeMagnitude_m2 / R_m2;
solution.isIllConditioned = solution.conditioning <= sqrt(eps);
end

function angle_rad = nearestEquivalent(baseAngle_rad, referenceAngle_rad)
angle_rad = baseAngle_rad + 2*pi .* round( ...
    (referenceAngle_rad-baseAngle_rad) ./ (2*pi));
end
