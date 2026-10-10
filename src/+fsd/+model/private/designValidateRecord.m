function designValidateRecord(value, kind, core)
%DESIGNVALIDATERECORD Reconstruct definitions and identity, not just stored flags.
designRequire(isstruct(value) && isscalar(value) && all(isfield(value, ...
    ["schemaVersion","kind","definitionSI","identity","metadata"])) && ...
    isequal(value.kind,kind),"Invalid design record.");
d = value.definitionSI; d.metadata = value.metadata;
expected = core(d);
designRequire(isequaln(value,expected),"Inconsistent design definition/identity.");
end
