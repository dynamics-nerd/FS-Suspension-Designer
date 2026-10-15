function seedPlainData(value)
%SEEDPLAINDATA Construction records contain data, never handles/callbacks.
if isstruct(value)
    names=fieldnames(value);
    for j=1:numel(value)
        for k=1:numel(names), seedPlainData(value(j).(names{k})); end
    end
elseif iscell(value)
    for j=1:numel(value), seedPlainData(value{j}); end
else
    seedRequire(isnumeric(value) || islogical(value) || ischar(value) || isstring(value), ...
        'Construction records must contain plain MATLAB data.');
end
end
