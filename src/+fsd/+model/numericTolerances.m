function tolerances = numericTolerances()
%NUMERICTOLERANCES Floating-point comparison tolerances for the core.
%   These values are software tolerances, not manufacturing or design
%   tolerances.

tolerances = struct( ...
    "AbsTol_m", 1e-9, ...
    "RelTol", 1e-9);
end

