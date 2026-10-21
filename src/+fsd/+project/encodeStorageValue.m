function encoded=encodeStorageValue(value)
%ENCODESTORAGEVALUE Lossless plain-value transport without nested string objects.
% Numeric/logical/char data is untouched. String size/missingness is explicit.
% Reserved field names in original structs are escaped, never reinterpreted.
if isstruct(value)
    names=fieldnames(value); encoded=value;
    for j=1:numel(value)
        for k=1:numel(names), encoded(j).(names{k})=fsd.project.encodeStorageValue(value(j).(names{k})); end
    end
    if any(ismember(names,{'fsdTextStorageV1','fsdStructStorageV1'}))
        encoded=struct('fsdStructStorageV1',{encoded});
    end
elseif iscell(value)
    encoded=value;
    for j=1:numel(value), encoded{j}=fsd.project.encodeStorageValue(value{j}); end
elseif isstring(value)
    payload={size(value),reshape(cellstr(value(:)),size(value)),ismissing(value)};
    encoded=struct('fsdTextStorageV1',{payload});
else
    projectRequire(isnumeric(value) || islogical(value) || ischar(value),'Storage supports only plain MATLAB values.');
    encoded=value;
end
end
