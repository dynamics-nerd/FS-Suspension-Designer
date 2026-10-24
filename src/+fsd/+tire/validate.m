function valid=validate(tire)
%VALIDATE Canonical reconstruction, including component identities.
assert(isstruct(tire)&&isscalar(tire)&&isfield(tire,'definition'),'fsd:tire:InvalidDefinition','Native tire required.');
assert(isequaln(tire,fsd.tire.create(tire.definition)),'fsd:tire:InvalidDefinition','Tire definition/identity mismatch.');
assert(canonicalNumerics(tire),'fsd:tire:InvalidDefinition','Use create to normalize all numeric declarations to double.');
valid=true;
end
function valid=canonicalNumerics(v)
valid=true;
if isnumeric(v)||islogical(v), valid=isa(v,'double');
elseif isstruct(v)
    for n=string(fieldnames(v))'
        if ~canonicalNumerics(v.(n)), valid=false; return; end
    end
end
end
