function options = searchSettings(input,variableCount)
%SEARCHSETTINGS Validate native controller controls without executing a search.
% Additive adapter: the historical private normalizer remains authoritative.
if nargin<1, input=struct(); end
requireSynthesis(isnumeric(variableCount) && isreal(variableCount) && isscalar(variableCount) && ...
    isfinite(variableCount) && variableCount>=0 && fix(variableCount)==variableCount,'Invalid variable count.');
options=searchOptions(input,variableCount);
end
