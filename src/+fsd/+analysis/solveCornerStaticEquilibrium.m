function result = solveCornerStaticEquilibrium(model, actuation, mechanical, targetSupport_N, options)
%SOLVECORNERSTATICEQUILIBRIUM Local prescribed-demand balance on validated path.
% No hidden suspension/rocker solve; not heave/pitch/roll chassis equilibrium.
if nargin < 5, options = struct; end
options = cornerEquilibriumInputs(model,actuation,mechanical,targetSupport_N,options);
result = cornerEquilibriumCore(model,actuation,mechanical,targetSupport_N,options);
end
