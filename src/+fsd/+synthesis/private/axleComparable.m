function value = axleComparable(value)
%AXLECOMPARABLE Ignore only native analysis timing during algebraic reconstruction.
if iscell(value)
    value=cellfun(@axleComparable,value,'UniformOutput',false);
elseif isstruct(value)
    remove=intersect(fieldnames(value),{'elapsedTime_s','solverElapsedTime_s','analysisElapsedTime_s'});
    if ~isempty(remove), value=rmfield(value,remove); end
    names=fieldnames(value);
    for i=1:numel(value)
        for j=1:numel(names), value(i).(names{j})=axleComparable(value(i).(names{j})); end
    end
end
end
