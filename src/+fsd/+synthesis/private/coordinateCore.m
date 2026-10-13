function output = coordinateCore(space,vector,direction)
%COORDINATECORE Exact endpoints, frozen axes=0; SI affine map on closed box.
requireSynthesis(isnumeric(vector) && isreal(vector) && (isvector(vector) || isempty(vector)) && ...
    numel(vector)==numel(space.variables) && all(isfinite(vector)), 'Invalid variable vector.');
vector = double(vector(:)); lo = space.lower_m; hi = space.upper_m; active = space.active;
if direction == "NORMALIZE"
    requireSynthesis(all(vector>=lo & vector<=hi),'Physical vector outside bounds.');
    output = zeros(size(vector)); output(active) = (vector(active)-lo(active))./(hi(active)-lo(active));
else
    requireSynthesis(all(vector>=0 & vector<=1) && all(vector(~active)==0),'Normalized vector outside bounds or frozen axis nonzero.');
    output = lo; output(active) = lo(active)+vector(active).*(hi(active)-lo(active));
    output(vector==1 & active) = hi(vector==1 & active);
    % Keep the original seed bit-identical despite the affine round trip.
    seedU = zeros(size(vector)); seedU(active) = (space.initial_m(active)-lo(active))./(hi(active)-lo(active));
    output(vector==seedU) = space.initial_m(vector==seedU);
end
end
