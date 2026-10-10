function scope = designScope(kind, id, cornerId)
%DESIGNSCOPE Typed scope; component/hardpoint IDs do not substitute for corner IDs.
if nargin < 3, cornerId = ""; end
kind = string(kind); id = string(id); cornerId = string(cornerId);
designRequire(isscalar(kind) && isscalar(id) && isscalar(cornerId) && ...
    ~ismissing(kind) && ~ismissing(id) && ~ismissing(cornerId),"Invalid scope text.");
switch kind
    case "VEHICLE", ok = id == "VEHICLE" && cornerId == "";
    case "AXLE", ok = any(id == ["FRONT","REAR"]) && cornerId == "";
    case "CORNER", ok = any(id == ["FL","FR","RL","RR"]) && cornerId == "";
    case "COMPONENT"
        ok = ~isempty(regexp(id,'^[A-Z][A-Z0-9_]*$','once')) && any(cornerId == ["FL","FR","RL","RR"]);
    case "HARDPOINT"
        ok = any(cornerId == ["FL","FR","RL","RR"]) && ...
            any(id == cornerId+"_"+fsd.model.requiredHardpointRoles());
    otherwise, ok = false;
end
designRequire(ok,"Scope ID/kind/corner mismatch.");
scope = struct("kind",kind,"id",id,"cornerId",cornerId);
end
