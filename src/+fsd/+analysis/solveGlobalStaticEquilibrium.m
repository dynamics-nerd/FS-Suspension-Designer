function result = solveGlobalStaticEquilibrium(system, initialGuesses, solverOptions)
%SOLVEGLOBALSTATICEQUILIBRIUM Coupled rigid-chassis static equilibrium on sampled paths.
% LOWEST_ENERGY_STABLE selects only a unique lowest-energy LOCAL_STABLE_MINIMUM,
% including singleton searches. NaN means no selection, not necessarily no roots.
% UNIQUE_ONLY selects one found root irrespective of its stability classification.
o = globalSolverOptions(solverOptions);
if ~isnumeric(initialGuesses) || ~isreal(initialGuesses) || size(initialGuesses,1) ~= 7 || ...
        isempty(initialGuesses) || any(~isfinite(initialGuesses),"all")
    error("fsd:analysis:InvalidGlobalStaticInput","Initial guesses must be finite SI 7-by-N.");
end
if any(initialGuesses < o.bounds(:,1) | initialGuesses > o.bounds(:,2),"all")
    error("fsd:analysis:InvalidGlobalStaticInput","Initial guesses outside explicit search box.");
end
prepared = fsd.analysis.prepareGlobalStaticSystem(system);
attempts = cell(size(initialGuesses,2),1);
for i = 1:numel(attempts)
    initial = globalCoordinateInput(initialGuesses(:,i));
    [q,diagnostics] = globalSolveCore(prepared,initial,o);
    attempts{i} = struct("initialGuess",initial,"solution",globalSolutionCore(prepared,q,o), ...
        "diagnostics",diagnostics);
end
[alternatives,selected,status] = globalSelectionCore(attempts,o);
result = struct("schemaVersion","0.10.0","kind","GlobalStaticEquilibriumResult", ...
    "systemIdentity",system.identity,"solverOptions",o,"initialGuesses",initialGuesses, ...
    "attempts",{attempts},"alternatives",{alternatives},"selectedIndex",selected, ...
    "status",status,"rootCompleteness","SUPPLIED_SEEDS_ONLY", ...
    "performance",prepared.performance);
timer = tic; globalVerifyResult(prepared,result);
result.performance.resultValidationTime_s = toc(timer);
end
