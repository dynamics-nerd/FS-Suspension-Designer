function budget = staticLoadNumericalBudget(matrix, rhs, solution)
%STATICLOADNUMERICALBUDGET Scaled algebraic roundoff, NOT balance/physical tolerance.
% Policy SL-32 in docs/vehicle-static-equilibrium.md. All rows have force units.
% gamma32 is a conservative arithmetic guard for the small dense products,
% factorization/back substitution and coefficient construction; not metrology.
gamma = 32*eps/(1-32*eps);
singular = svd(matrix); matrixNorm = singular(1);
gap = singular(end)-gamma*matrixNorm;
rowError = gamma*(abs(matrix)*abs(solution)+abs(rhs));
residual = matrix*solution-rhs;
forwardError = (norm(residual)+norm(rowError))/gap;
budget = struct("policy","SL-32","gamma",gamma, ...
    "reciprocalCondition",singular(end)/matrixNorm, ...
    "loadRoundoff_N",forwardError, ...
    "scaledResidualBudget_N",rowError+sum(abs(matrix),2)*forwardError);
end
