function diagnostics = axleResultDiagnostics(search)
%AXLERESULTDIAGNOSTICS No implicit winner or universal feasibility claim.
diagnostics=strings(0,1);
if isempty(search.eligibleIndices), diagnostics(end+1,1)="NO_FULLY_EVALUATED_SAMPLED_FEASIBLE_AXLE"; end
if isnan(search.selectedIndex), diagnostics(end+1,1)="NO_AUTOMATIC_WINNER_WITHOUT_COMPLETE_EXPLICIT_SCORE"; end
end
