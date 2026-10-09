function path = globalPathCore(s, wc, branch)
%GLOBALPATHCORE No reordering across gaps, no extrapolation, no source re-solves.
m = s.mechanical; z = m.path.achievedWheelTravel_m; c = m.path.damperCompression_m;
good = m.path.converged & ~m.path.isIllConditioned & all(isfinite(wc),2) & ...
    isfinite(m.damperMotionRatio) & m.motionRatioStatus == "AVAILABLE" & ...
    m.feasibleRelativeToProvidedLimits & isfinite(branch) & branch ~= 0;
segments = cell(0,1); start = 1; n = numel(z);
while start <= n
    if ~good(start), start = start+1; continue; end
    last = start;
    direction = 0;
    while last < n && good(last+1) && branch(last+1) == branch(last)
        dz = z(last+1)-z(last);
        if abs(dz) <= 64*eps(max([abs(z(last:last+1));1])), break; end
        if direction ~= 0 && sign(dz) ~= direction, break; end
        direction = sign(dz); last = last+1;
    end
    if last-start >= 2
        indices = start:last;
        if direction < 0, indices = fliplr(indices); end % reverse only a proven monotone segment
        values = [wc(indices,:),c(indices)]';
        pp = pchip(z(indices),values);
        derivative = globalPpDerivative(pp);
        atSamples = ppval(derivative,z(indices));
        difference = atSamples(4,:)'-m.damperMotionRatio(indices);
        secondOK = m.derivativeStatus(indices) == "AVAILABLE";
        segments{end+1,1} = struct("indices",indices,"interval_m",[min(z(indices)),max(z(indices))], ...
            "pp",pp,"first",derivative,"second",globalPpDerivative(derivative), ...
            "curvatureResolved",secondOK,"sourceMR",m.damperMotionRatio(indices), ...
            "motionRatioDifference",difference,"branchSign",branch(start)); %#ok<AGROW>
    end
    start = last+1;
end
path = struct("segments",{segments},"validSamples",good, ...
    "requestedWheelTravel_m",m.path.requestedWheelTravel_m, ...
    "sourceConverged",m.path.converged,"mechanicalFeasible",m.feasibleRelativeToProvidedLimits, ...
    "originalWheelTravel_m",z,"originalWheelCenters_m",wc, ...
    "originalCompression_m",c,"sourceStatuses",m.motionRatioStatus, ...
    "approximation","SAMPLED_PATH_APPROXIMATION");
end
