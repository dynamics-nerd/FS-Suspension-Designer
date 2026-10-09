function [alternatives, selected, status] = globalSelectionCore(attempts, o)
%GLOBALSELECTIONCORE Preserve all valid stationary configurations found by supplied seeds.
alternatives = cell(0,1);
tol = repmat(o.positionTolerance_m,7,1); tol(2:3) = o.angleTolerance_rad;
for i = 1:numel(attempts)
    candidate = attempts{i}.solution;
    if ~candidate.converged, continue; end
    duplicate = false;
    for j = 1:numel(alternatives)
        duplicate = duplicate || all(abs(candidate.state.q-alternatives{j}.state.q) <= tol);
    end
    if ~duplicate, alternatives{end+1,1} = candidate; end %#ok<AGROW>
end
selected = NaN; status = "NO_GLOBAL_EQUILIBRIUM_FOUND";
if isscalar(alternatives)
    status = "UNIQUE_FOUND_EQUILIBRIUM";
elseif numel(alternatives) > 1
    status = "MULTIPLE_FOUND_EQUILIBRIA";
end
% Search status counts roots, not policy-eligible or selected configurations.
% Apply the requested policy uniformly to zero, one and many alternatives.
if o.selection == "UNIQUE_ONLY"
    if isscalar(alternatives), selected = 1; end
elseif o.selection == "LOWEST_ENERGY_STABLE"
    indices = find(cellfun(@(x) x.stability == "LOCAL_STABLE_MINIMUM",alternatives));
    if isempty(indices), return; end
    values = cellfun(@(x) x.state.potentialEnergy_J,alternatives(indices),"UniformOutput",false);
    % An invalid eligible energy cannot certify a minimum of the eligible set.
    if ~all(cellfun(@(u) isnumeric(u) && isreal(u) && isscalar(u) && isfinite(u),values))
        return;
    end
    energies = cell2mat(values);
    choices = indices(energies == min(energies));
    if isscalar(choices), selected = choices; end % exact ties remain unselected
end
end
