function [value,status] = seedReferenceValue(parameters,id)
%SEEDREFERENCEVALUE Role before availability, matching the v0.16 physical gate.
value=[]; status="UNKNOWN";
for j=1:numel(parameters)
    d=parameters{j}.definitionSI;
    if d.id==string(id), [value,status]=seedPhysicalValue(d); return; end
end
end
