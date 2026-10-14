function value = workflowComparable(value)
%WORKFLOWCOMPARABLE Ignore only wall-clock fields during algebraic replay.
if isstruct(value)
    names=fieldnames(value); remove=contains(lower(string(names)),'elapsedtime');
    if any(remove), value=rmfield(value,names(remove)); end
    names=fieldnames(value);
    for j=1:numel(value)
        for k=1:numel(names), value(j).(names{k})=workflowComparable(value(j).(names{k})); end
    end
elseif iscell(value)
    for j=1:numel(value), value{j}=workflowComparable(value{j}); end
end
end
