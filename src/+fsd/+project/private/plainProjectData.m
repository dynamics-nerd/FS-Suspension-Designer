function plainProjectData(value)
%PLAINPROJECTDATA Same plain-data predicate with grouped primitive leaves.
% Only containers recurse. Leaves retain the original numeric/logical/char/string
% predicate, including its fallback for less common numeric classes.
if isstruct(value)
    for j=1:numel(value), visit(struct2cell(value(j))); end
elseif iscell(value)
    visit(value);
else
    require(isnumeric(value) || islogical(value) || ischar(value) || isstring(value));
end
end
function visit(values)
containers=cellfun('isclass',values,'struct') | cellfun('isclass',values,'cell');
leaves=values(~containers);
common=cellfun('isclass',leaves,'double') | cellfun('isclass',leaves,'single') | ...
    cellfun('isclass',leaves,'logical') | cellfun('isclass',leaves,'char') | cellfun('isclass',leaves,'string');
others=leaves(~common);
require(all(cellfun(@(v)isnumeric(v) || islogical(v) || ischar(v) || isstring(v),others),'all'));
indices=find(containers);
for k=indices(:)', plainProjectData(values{k}); end
end
function require(valid)
assert(valid,'fsd:project:InvalidInput','Project records may contain only plain MATLAB data, not executable objects.');
end
