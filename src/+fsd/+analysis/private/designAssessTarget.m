function assessment = designAssessTarget(target, data)
%DESIGNASSESSTARGET Sampled comparisons; interpolate target only, never actual results.
t = target.definitionSI; curve = any(t.type == ["CURVE_TARGET","CURVE_BAND"]);
requested = [0,0];
if ~isempty(t.x), requested = [min(t.x),max(t.x)]; end
if curve
    grid = unique([requested';data.x(data.x >= requested(1) & data.x <= requested(2))]);
else
    grid = 0; if ~isempty(t.x), grid = t.x; end
end
n = numel(grid); y = nan(n,1); valid = false(n,1);
reasons = repmat("NO_RESULT_SAMPLE_AT_REQUESTED_COORDINATE",n,1);
if isempty(data.x), reasons(:) = data.missingReason; end
[found,j] = ismember(grid,data.x);
y(found) = data.y(j(found)); valid(found) = data.valid(j(found)); reasons(found) = data.reasons(j(found));
connected = false(max(n-1,0),1);
for k = 1:n-1
    connected(k) = found(k) && found(k+1) && j(k+1) == j(k)+1 && data.connected(j(k));
end
value = valuesAt(t,"value",grid,curve); lower = valuesAt(t,"lower",grid,curve);
upper = valuesAt(t,"upper",grid,curve); tolerance = valuesAt(t,"tolerance",grid,curve);
compared = y; if t.transform == "ABS", compared = abs(y); end
[deviation,violation] = designTargetErrors(t,compared,value,lower,upper,tolerance);
deviation(~valid) = NaN; violation(~valid) = NaN;
normalized = nan(n,1); normalizedViolation = normalized;
if ~isempty(t.normalizationScale)
    normalized = deviation/t.normalizationScale; normalizedViolation = violation/t.normalizationScale;
end
edges = connected & valid(1:end-1) & valid(2:end);
widths = diff(grid); evaluatedLength = sum(widths(edges));
coverage = double(all(valid));
if curve, coverage = evaluatedLength/(requested(2)-requested(1)); end
status = "NOT_EVALUATED";
if all(valid) && all(connected)
    status = "SAMPLED_PASS"; if any(violation(valid) > 0), status = "SAMPLED_FAIL"; end
elseif any(valid), status = "PARTIALLY_EVALUATED";
end
left = grid(1:end-1); right = grid(2:end);
intervals = [left(edges),right(edges)];
assessment = struct("id",t.id,"kind","TARGET","metricId",t.metricId,"scope",t.scope, ...
    "strength",t.strength,"unit",t.unit,"independentVariable",t.independentVariable, ...
    "xUnit",t.xUnit,"x",grid,"actual",y,"compared",compared,"nominal",value, ...
    "lower",lower,"upper",upper,"tolerance",tolerance,"deviation",deviation, ...
    "violation",violation,"normalizedResidual",normalized,"normalizedViolation",normalizedViolation, ...
    "valid",valid,"reasons",reasons,"connected",connected,"status",status, ...
    "demonstratedViolation",any(violation(valid) > 0),"requestedDomain",requested, ...
    "availableIntervals",intervals,"evaluatedSampleCount",sum(valid), ...
    "unavailableSampleCount",sum(~valid),"sampleCoverage",sum(valid)/n,"domainCoverage",coverage, ...
    "evaluatedDomainLength",evaluatedLength,"maximumAbsoluteError",maximum(abs(deviation(valid))), ...
    "maximumNormalizedError",maximum(abs(normalized(valid))), ...
    "rmsNormalizedError",rmsValue(normalized,grid,edges,curve), ...
    "rmsNormalizedViolation",rmsValue(normalizedViolation,grid,edges,curve), ...
    "violationCount",sum(violation(valid) > 0),"aggregatesPartial",status == "PARTIALLY_EVALUATED", ...
    "sourceIdentity",data.sourceIdentity,"verificationDomain","SAMPLES_ONLY");
end

function values = valuesAt(t, field, grid, curve)
v = t.(field); values = nan(size(grid));
if isempty(v), return; end
if curve
    x = t.x;
    if all(diff(x) < 0), x = flipud(x); v = flipud(v); end
    values = interp1(x,v,grid,"linear",NaN); % target interpolation, no extrapolation
else, values(:) = v;
end
end

function value = maximum(x)
value = NaN; if ~isempty(x) && all(isfinite(x)), value = max(x); end
end

function value = rmsValue(residual, x, edges, curve)
value = NaN;
if ~curve
    if isfinite(residual), value = abs(residual); end
elseif any(edges)
    i = find(edges); dx = x(i+1)-x(i);
    value = sqrt(sum(dx.*(residual(i).^2+residual(i+1).^2)/2)/sum(dx));
end
end
