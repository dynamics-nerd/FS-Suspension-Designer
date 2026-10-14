function plainProjectData(value)
%PLAINPROJECTDATA Serializable data only, no callbacks, handles or objects.
if isstruct(value)
    names=fieldnames(value);
    for j=1:numel(value)
        for k=1:numel(names), plainProjectData(value(j).(names{k})); end
    end
elseif iscell(value)
    for j=1:numel(value), plainProjectData(value{j}); end
else
    projectRequire(isnumeric(value) || islogical(value) || ischar(value) || isstring(value), ...
        'Project records may contain only plain MATLAB data, not executable objects.');
end
end
