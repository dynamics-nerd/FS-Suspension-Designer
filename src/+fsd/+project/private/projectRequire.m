function projectRequire(condition,message)
%PROJECTREQUIRE Closed data-contract checks, not physical acceptance criteria.
if ~condition, error('fsd:project:InvalidInput','%s',message); end
end
