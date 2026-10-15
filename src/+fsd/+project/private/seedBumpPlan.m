function plan = seedBumpPlan(input)
%SEEDBUMPPLAN SI declared grid and the historical numerical option contract.
projectRequire(isstruct(input) && isscalar(input) && isfield(input,'travel_m') && ...
    all(ismember(string(fieldnames(input)),["travel_m","solverOptions"])), 'Explicit seed BUMP plan required.');
z=input.travel_m; projectRequire(isnumeric(z) && isreal(z) && isvector(z) && ~isempty(z) && all(isfinite(z)), ...
    'Finite nonempty seed BUMP travel grid required.'); z=double(z(:));
projectRequire(isscalar(z) || all(diff(z)>0) || all(diff(z)<0), 'Strictly monotone seed BUMP grid required.');
opts=struct(); if isfield(input,'solverOptions'), opts=input.solverOptions; end
plan=struct('travel_m',z,'solverOptions',fsd.kinematics.solverSettings(opts));
end
