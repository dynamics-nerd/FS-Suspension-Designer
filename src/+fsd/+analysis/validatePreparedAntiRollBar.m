function valid=validatePreparedAntiRollBar(input)
%VALIDATEPREPAREDANTIROLLBAR Prepared values are never a trust token.
assert(isstruct(input)&&isscalar(input)&&all(isfield(input,{'bar','sources'}))&& ...
    isequaln(input,fsd.analysis.prepareAntiRollBar(input.bar,input.sources)), ...
    'fsd:analysis:InvalidAntiRollBar','Prepared ARB differs from canonical sources.');
valid=true;
end
