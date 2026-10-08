function analysis = springDamperSweepCore(model, source, path, velocity)
%SPRINGDAMPERSWEEPCORE No validation/solves inside the per-sample force loop.
timer = tic;
[mr, second, statuses, quality] = springDamperPathDerivatives(model,source,path);
steps = diff(path.requestedWheelTravel_m);
if all(path.converged) && numel(steps) >= 2 && ~(all(steps > 0) || all(steps < 0))
    mr(:) = NaN; second(:) = NaN;
    statuses(:) = "UNAVAILABLE_NONMONOTONIC_WHEEL_TRAVEL";
    quality.motionRatioStatus(:) = statuses;
end
n = numel(mr); cells = cell(n,1);
for i = 1:n
    cells{i} = springDamperStateCore(model,path.damperLength_m(i), ...
        path.damperCompression_m(i),path.converged(i), ...
        mr(i),second(i),statuses(i),velocity(i),"wheel");
    cells{i}.motionRatioStatus = quality.motionRatioStatus(i);
end
states = vertcat(cells{:});
analysis = struct("schemaVersion","0.8.0","kind","SpringDamperSweepAnalysis", ...
    "modelIdentity",model.identity,"source",source,"path",path, ...
    "inputWheelVelocity_m_per_s",velocity,"states",states,"derivativeDiagnostics",quality);
names = fieldnames(states);
for i = 1:numel(names)
    name = names{i};
    if isnumeric(states(1).(name)) || islogical(states(1).(name))
        analysis.(name) = reshape([states.(name)],[],1);
    else
        analysis.(name) = reshape(string({states.(name)}),[],1);
    end
end
analysis.requestedWheelTravel_m = path.requestedWheelTravel_m;
analysis.achievedWheelTravel_m = path.achievedWheelTravel_m;
analysis.wheelRateMigration_N_per_m = nan(n,1);
index = find(path.requestedWheelTravel_m == 0);
analysis.staticReferenceAvailable = isscalar(index) && ...
    isfinite(analysis.wheelRateTotal_N_per_m(index));
analysis.staticReferenceIndex = NaN;
analysis.nominalWheelRate_N_per_m = NaN;
analysis.nominalGeometricWheelRate_N_per_m = NaN;
if analysis.staticReferenceAvailable
    analysis.staticReferenceIndex = index;
    analysis.nominalWheelRate_N_per_m = analysis.wheelRateTotal_N_per_m(index);
    analysis.nominalGeometricWheelRate_N_per_m = analysis.wheelRateGeometric_N_per_m(index);
    analysis.wheelRateMigration_N_per_m = ...
        analysis.wheelRateTotal_N_per_m-analysis.nominalWheelRate_N_per_m;
end
analysis.metrics = springDamperMetrics(analysis);
analysis.validWheelRateSampleCount = sum(isfinite(analysis.wheelRateTotal_N_per_m));
analysis.wheelRateCoverageComplete = analysis.validWheelRateSampleCount == n;
analysis.elapsedTime_s = toc(timer);
end
