function policy = springDamperDerivativePolicy(model)
%SPRINGDAMPERDERIVATIVEPOLICY Deterministic numerical budgets, not design limits.
% 16 ulps is a short-arithmetic allowance, not a physical/statistical bound.
% 1e-3 relative allows at most a per-mille estimated numerical perturbation;
% 1e-6 natural-scale floor handles zero/cancellation without division by zero.
policy = struct("methodVersion","F01-1","roundoffUlps",16, ...
    "relativeBudget",1e-3,"absoluteScaleFraction",1e-6, ...
    "referenceLength_m",model.spring.freeLength_m, ...
    "referenceRate_N_per_m",model.spring.rate_N_per_m);
end
