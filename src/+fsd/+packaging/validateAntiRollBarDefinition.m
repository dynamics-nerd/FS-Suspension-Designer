function valid=validateAntiRollBarDefinition(input)
%VALIDATEANTIROLLBARDEFINITION Reconstruct declaration, never infer dimensions.
assert(isstruct(input)&&isscalar(input)&&isfield(input,'definition')&& ...
    isequaln(input,fsd.packaging.createAntiRollBarDefinition(input.definition)), ...
    'fsd:packaging:InvalidAntiRollBar','ARB packaging identity mismatch.');
valid=true;
end
