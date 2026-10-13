function requireSynthesis(condition, message)
%REQUIRESYNTHESIS Stable input-contract error, not an engineering tolerance.
if ~condition, error('fsd:synthesis:InvalidInput','%s',message); end
end
