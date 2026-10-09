function value = globalPathValue(path, z)
%GLOBALPATHVALUE Query only a connected valid segment, never extrapolate.
value = struct("available",false,"status","OUTSIDE_VALID_PATH", ...
    "p",nan(3,1),"dp",nan(3,1),"ddp",nan(3,1),"c",NaN,"mr",NaN, ...
    "c2",NaN,"curvatureResolved",false,"motionRatioDifference",NaN,"segmentIndex",NaN);
for i = 1:numel(path.segments)
    s = path.segments{i}; interval = s.interval_m;
    if z < interval(1) || z > interval(2), continue; end
    a = ppval(s.pp,z); b = ppval(s.first,z); d = ppval(s.second,z);
    breaks = s.pp.breaks;
    j = find(breaks <= z,1,"last"); j = min(j,numel(breaks)-1);
    resolved = all(s.curvatureResolved(j:j+1));
    resolved = resolved && z > interval(1)+64*eps(max(abs(z),1)) && ...
        z < interval(2)-64*eps(max(abs(z),1));
    % PCHIP is only C1: reject a bilateral Hessian at an unresolved knot jump.
    knot = find(abs(breaks-z) <= 64*eps(max(abs(z),1)),1);
    if ~isempty(knot) && knot > 1 && knot < numel(breaks)
        left = reshape(s.second.coefs((knot-2)*4+(1:4),:),4,[]);
        right = reshape(s.second.coefs((knot-1)*4+(1:4),:),4,[]);
        step = breaks(knot)-breaks(knot-1);
        lv = left(:,1)*step+left(:,2); rv = right(:,2);
        resolved = resolved && all(abs(lv-rv) <= 1e-6+1e-3*max(abs(lv),abs(rv)));
    end
    old = interp1(breaks,s.sourceMR,z,"linear");
    difference = b(4)-old;
    % F01-1 first derivative quality plus interpolation/source consistency.
    if abs(difference) > 1e-6+1e-3*abs(old)
        value.status = "INTERPOLATED_MR_DISAGREEMENT"; return;
    end
    value = struct("available",true,"status","AVAILABLE","p",a(1:3), ...
        "dp",b(1:3),"ddp",d(1:3),"c",a(4),"mr",b(4),"c2",d(4), ...
        "curvatureResolved",resolved,"motionRatioDifference",difference,"segmentIndex",i);
    return;
end
% Preserve the reason for an interior gap, distinct from a query outside samples.
requested = path.requestedWheelTravel_m;
if z < min(requested) || z > max(requested)
    value.status = "OUTSIDE_SAMPLED_PATH"; return;
end
touch = abs(requested-z) <= 64*eps(max(abs(z),1));
for j = 1:numel(requested)-1
    if z >= min(requested(j:j+1)) && z <= max(requested(j:j+1))
        touch(j:j+1) = true;
    end
end
if any(~path.sourceConverged(touch))
    value.status = "SOURCE_FAILURE_PATH_GAP";
elseif any(~path.mechanicalFeasible(touch))
    value.status = "MECHANICAL_LIMIT_PATH_GAP";
elseif any(path.sourceStatuses(touch) ~= "AVAILABLE")
    index = find(touch & path.sourceStatuses ~= "AVAILABLE",1);
    value.status = path.sourceStatuses(index);
else
    value.status = "INSUFFICIENT_OR_DISCONNECTED_VALID_PATH";
end
end
