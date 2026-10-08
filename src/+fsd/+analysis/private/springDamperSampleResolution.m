function [errorC, errorZ, kind] = springDamperSampleResolution(model, source, path, policy)
%SPRINGDAMPERSAMPLERESOLUTION Representation/operation proxies, not physical uncertainty.
% Constraint length residuals are indicators only, NOT position-error bounds.
n = numel(path.converged); errorC = nan(n,1); errorZ = errorC;
q = policy.roundoffUlps;
kind = "ROUNDOFF_ONLY_PRESCRIBED";
if source.kind == "ActuationSweep", kind = "ROUNDOFF_AND_RESIDUAL_INDICATORS"; end
for i = 1:n
    if ~path.converged(i), continue; end
    c = path.damperCompression_m(i); z = path.achievedWheelTravel_m(i);
    errorC(i) = q*eps(abs(c)); errorZ(i) = q*eps(abs(z));
    if source.kind == "ActuationSweep"
        a = source.sweep.results(i); k = a.sourceResult;
        l0 = model.derivedStaticGeometry.damperStaticLength_m;
        scale = max(abs([model.actuationIdentity.rockerDamperPointStatic_m, ...
            model.actuationIdentity.damperChassisPoint_m, ...
            a.rockerDamperPointCurrent_m,a.suspensionAttachmentCurrent_m, ...
            k.state.xyz_m(:)']));
        indicator = max(abs(k.diagnostics.lengthErrors_m)) + ...
            abs(a.actuationRodLengthResidual_m);
        condition = max(a.conditioning,sqrt(eps));
        errorC(i) = errorC(i)+q*(eps(l0)+eps(path.damperLength_m(i))) + ...
            (q*eps(scale)+indicator)/condition;
        errorZ(i) = errorZ(i)+q*(eps(abs(k.state.wheelCenter_m(3))) + ...
            eps(abs(k.uprightPose.referencePointStatic_m(3))))+indicator;
    end
end
end
