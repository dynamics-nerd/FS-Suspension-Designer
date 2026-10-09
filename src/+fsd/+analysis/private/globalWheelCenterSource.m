function [wc, branch] = globalWheelCenterSource(s)
%GLOBALWHEELCENTERSOURCE Production sources are validated fixed-inboard bump paths.
id = "fsd:analysis:InvalidGlobalStaticSystem";
p = s.mechanical.path; n = numel(p.converged); wc = nan(n,3); branch = nan(n,1);
if s.pathKind == "IDEAL_PRESCRIBED_3D"
    if ~isequal(s.mechanical.source.kind,"PrescribedDamperPath") || ...
            ~isnumeric(s.idealWheelCenterPath_m) || ~isreal(s.idealWheelCenterPath_m) || ...
            ~isequal(size(s.idealWheelCenterPath_m),[n,3]) || ...
            any(~isfinite(s.idealWheelCenterPath_m),"all")
        error(id,"Invalid explicit ideal 3D fixture; not a solved mechanism.");
    end
    wc = s.idealWheelCenterPath_m; branch(:) = 1;
else
    if ~isequal(s.mechanical.source.kind,"ActuationSweep")
        error(id,"Production path must be an ActuationSweep, fixed rack zero.");
    end
    results = s.mechanical.source.sweep.results;
    for j = 1:n
        r = results(j);
        if ~isequal(r.sourceResult.kind,"KinematicResult")
            error(id,"Mixed steering/rack paths are not a one-dimensional bump source.");
        end
        if r.converged
            wc(j,:) = r.sourceResult.state.wheelCenter_m;
            d = r.diagnostics;
            branch(j) = sign(-d.constraintA_m2*sin(r.rockerAngle_rad)+ ...
                d.constraintB_m2*cos(r.rockerAngle_rad));
        end
    end
end
nominal = fsd.model.getPoint(s.geometry,s.geometry.cornerId+"_WHEEL_CENTER");
tol = 1e-9; % existing geometric software tolerance, not a physical clearance
valid = p.converged;
if any(abs(wc(valid,3)-nominal(3)-p.achievedWheelTravel_m(valid)) > tol)
    error(id,"WC body Z must agree with canonical wheel travel.");
end
end
