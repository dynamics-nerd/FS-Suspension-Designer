function [value,status] = seedPhysicalValue(d)
%SEEDPHYSICALVALUE No RULE/TARGET promotion or automatic interval midpoint.
value=[]; status="UNKNOWN";
if d.type=="RULE", status="RULE_IS_NOT_A_PHYSICAL_INPUT"; return; end
if d.type=="TARGET", status="TARGET_IS_NOT_A_FACT"; return; end
if ~isempty(d.value) && ismember(d.availability,["KNOWN","ASSUMED","DERIVED"])
    value=d.value; status="AVAILABLE";
elseif ~isempty(d.bounds), status="INTERVAL_REQUIRES_EXPLICIT_NOMINAL";
end
end
