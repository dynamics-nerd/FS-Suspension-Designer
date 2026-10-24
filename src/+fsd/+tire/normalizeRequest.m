function q=normalizeRequest(q)
%NORMALIZEREQUEST Canonical defaults and channel order, without physical inputs.
assert(isstruct(q)&&isscalar(q)&&all(ismember(string(fieldnames(q)),["channels","domainPolicy"])), ...
    'fsd:tire:InvalidRequest','Unknown request fields.');
if ~isfield(q,'channels'), q.channels=["Fx";"Fy"]; end
if ~isfield(q,'domainPolicy'), q.domainPolicy="MARK"; end
q.channels=string(q.channels(:)); q.domainPolicy=string(q.domainPolicy);
assert(~isempty(q.channels)&&numel(unique(q.channels))==numel(q.channels)&&all(ismember(q.channels,["Fx","Fy","Mz"]))&& ...
    isscalar(q.domainPolicy)&&ismember(q.domainPolicy,["MARK","REJECT"]),'fsd:tire:InvalidRequest','Invalid channels or domain policy.');
end
