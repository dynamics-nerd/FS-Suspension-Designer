function report = verifyF01()
%VERIFYF01 Reproduce F-01 and measure warmed analysis, without modifying files.
root = fileparts(fileparts(mfilename("fullpath")));
oldPath = path; cleanup = onCleanup(@() path(oldPath));
addpath(root,fullfile(root,"src"));
[model,a,g] = springDamperFixture();
z = 0.01+[-1e-13;0;1e-13]; c = 0.5*z+3*z.^2;
synthetic = fsd.analysis.analyzePrescribedSpringDamperPath(model,z,c,0, ...
    struct("length","m","velocity","m/s"));
printCase("SYNTHETIC",1e-13,synthetic,13962);
spacings = [1e-4;1e-8;1e-9]; results = cell(3,1);
reference = rockerWheelRateReference(0.01,30000,0.02);
for i = 1:3
    h = spacings(i);
    b = fsd.kinematics.solveBumpSweep(g,0.01+[-h;0;h],"m");
    s = fsd.kinematics.solveActuationSweep(a,b);
    aa = fsd.analysis.analyzeActuationSweep(a,s);
    results{i} = fsd.analysis.analyzeSpringDamperSweep(model,a,s,aa,0.1,"m/s");
    printCase("ROCKER",h,results{i},reference);
end
% Source solves outside all mechanical timing/profiling.
b = fsd.kinematics.solveBumpSweep(g,(-20:2:20)',"mm");
s = fsd.kinematics.solveActuationSweep(a,b);
aa = fsd.analysis.analyzeActuationSweep(a,s);
times = zeros(3,2);
for i = 1:4
    timer = tic;
    r = fsd.analysis.analyzeSpringDamperSweep(model,a,s,aa,0.1,"m/s");
    wall = toc(timer);
    if i > 1, times(i-1,:) = [r.elapsedTime_s,wall]; end
end
profile clear; profile on;
fsd.analysis.analyzeSpringDamperSweep(model,a,s,aa,0.1,"m/s");
profile off; p = profile("info");
names = string({p.FunctionTable.FunctionName});
assert(~any(contains(names,["fsolve","fzero","solveBump","solveActuation"])));
index = find(endsWith(names,"springDamperPathDerivatives"));
assert(isscalar(index),"Derivative profile must identify its computational core.");
diagnosticTime = p.FunctionTable(index).TotalTime/p.FunctionTable(index).NumCalls;
report = struct("synthetic",synthetic,"rockerSpacings_m",spacings, ...
    "rockerResults",{results},"referenceWheelRate_N_per_m",reference, ...
    "stateCount",21,"medianCoreTime_s",median(times(:,1)), ...
    "medianPublicTime_s",median(times(:,2)), ...
    "profiledDerivativeDiagnosticsTimePerCall_s",diagnosticTime, ...
    "mechanicalNonlinearSolveCount",0);
fprintf("F01_PERF states=%d core_ms=%.6f public_ms=%.6f diagnostics_profile_ms=%.6f solves=0\n", ...
    report.stateCount,1000*report.medianCoreTime_s,1000*report.medianPublicTime_s,1000*diagnosticTime);
end

function printCase(kind,h,r,expected)
q = r.derivativeDiagnostics;
fprintf("F01_%s h=%.12g MR=%.12g MR_error=%.12g MR_status=%s\n", ...
    kind,h,r.damperMotionRatio(2),q.motionRatioAbsoluteError(2),r.motionRatioStatus(2));
fprintf("curvature_candidate=%.12g curvature_error=%.12g curvature_limit=%.12g published=%.12g status=%s\n", ...
    q.candidateCurvature_per_m(2),q.curvatureAbsoluteError_per_m(2), ...
    q.curvatureErrorLimit_per_m(2),r.motionRatioDerivative_per_m(2),r.derivativeStatus(2));
fprintf("Kw_candidate=%.12g Kw_error=%.12g Kw_limit=%.12g Kw_published=%.12g expected=%.12g status=%s\n", ...
    q.candidateWheelRate_N_per_m(2),q.wheelRateAbsoluteError_N_per_m(2), ...
    q.wheelRateErrorLimit_N_per_m(2),r.wheelRateTotal_N_per_m(2),expected,r.wheelRateStatus(2));
end
