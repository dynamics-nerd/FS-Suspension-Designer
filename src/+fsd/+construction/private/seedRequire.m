function seedRequire(condition,message)
%SEEDREQUIRE Construction record contract, not a physical exception allowlist.
if ~condition, error('fsd:construction:InvalidInput','%s',message); end
end
