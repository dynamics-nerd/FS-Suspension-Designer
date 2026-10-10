function value = designComparable(value)
%DESIGNCOMPARABLE Omit presentation/timing only when comparing reconstructed analysis.
if iscell(value)
    value = cellfun(@designComparable,value,"UniformOutput",false);
elseif isstruct(value)
    remove = intersect(fieldnames(value),{'metadata','displayName','elapsedTime_s', ...
        'solverElapsedTime_s','analysisElapsedTime_s'});
    if ~isempty(remove), value = rmfield(value,remove); end
    names = fieldnames(value);
    for i = 1:numel(value)
        for j = 1:numel(names), value(i).(names{j}) = designComparable(value(i).(names{j})); end
    end
end
end
