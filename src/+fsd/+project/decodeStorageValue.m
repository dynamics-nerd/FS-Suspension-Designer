function value=decodeStorageValue(encoded)
%DECODESTORAGEVALUE Inverse of encodeStorageValue; no evaluation/class loading.
if isstruct(encoded)
    names=fieldnames(encoded);
    if isfield(encoded,'fsdTextStorageV1')
        projectRequire(isscalar(encoded) && isscalar(names),'Invalid stored string marker.');
        p=encoded.fsdTextStorageV1;
        projectRequire(iscell(p) && isequal(size(p),[1 3]),'Invalid stored string payload.');
        shape=p{1}; text=p{2}; missingMask=p{3};
        projectRequire(isnumeric(shape) && isreal(shape) && isrow(shape) && numel(shape)>=2 && ...
            all(isfinite(shape)) && all(shape>=0) && all(fix(shape)==shape), 'Invalid stored string shape.');
        projectRequire(iscell(text) && islogical(missingMask) && isequal(size(text),shape) && ...
            isequal(size(missingMask),shape) && all(cellfun(@(s)ischar(s) && (isrow(s) || isempty(s)),text),'all'), ...
            'Stored text/missingness differs from its shape.');
        value=reshape(string(text),shape); value(missingMask)=missing;
    elseif isfield(encoded,'fsdStructStorageV1')
        projectRequire(isscalar(encoded) && isscalar(names) && isstruct(encoded.fsdStructStorageV1), ...
            'Invalid escaped struct marker.');
        value=decodeMembers(encoded.fsdStructStorageV1);
    else
        value=decodeMembers(encoded);
    end
elseif iscell(encoded)
    value=encoded;
    for j=1:numel(encoded), value{j}=fsd.project.decodeStorageValue(encoded{j}); end
else
    projectRequire(isnumeric(encoded) || islogical(encoded) || ischar(encoded),'Invalid storage value type.');
    value=encoded;
end
end
function value=decodeMembers(encoded)
% Bypass marker recognition at exactly the escaped original struct boundary.
names=fieldnames(encoded); value=encoded;
for j=1:numel(encoded)
    for k=1:numel(names), value(j).(names{k})=fsd.project.decodeStorageValue(encoded(j).(names{k})); end
end
end
