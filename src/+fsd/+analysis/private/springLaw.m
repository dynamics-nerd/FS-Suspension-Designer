function value = springLaw(spring, compression)
%SPRINGLAW Compression-only coil spring; ideal unloaded spring at free length.
raw = spring.preloadCompression_m+compression;
% Roundoff-only contact classification, not an engineering clearance.
tol = 64*eps(max([spring.freeLength_m,abs(compression),1]));
if abs(raw) <= tol, raw = 0; end
x = max(raw,0);
if raw < 0
    status = "SPRING_UNSEATED";
elseif raw == 0
    status = "SPRING_ENGAGEMENT_TRANSITION";
else
    status = "SPRING_COMPRESSED";
end
value = struct("springRawCompression_m",raw,"springCompression_m",x, ...
    "springGap_m",max(-raw,0),"springLength_m",spring.freeLength_m-x, ...
    "springAxialForce_N",spring.rate_N_per_m*x, ...
    "springStoredEnergy_J",0.5*spring.rate_N_per_m*x^2, ...
    "springStatus",status);
end
