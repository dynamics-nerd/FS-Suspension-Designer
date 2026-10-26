function valid=validateAntiRollBar(bar)
%VALIDATEANTIROLLBAR Reconstruct declaration and enforce canonical numeric types.
assert(isstruct(bar)&&isscalar(bar)&&isfield(bar,'definition')&& ...
    isequaln(bar,fsd.model.createAntiRollBar(bar.definition))&&canonical(bar), ...
    'fsd:model:InvalidAntiRollBar','ARB does not match its canonical declaration/identity.');
valid=true;
end
function ok=canonical(v)
ok=true;
if isnumeric(v)||islogical(v), ok=isa(v,'double');
elseif isstruct(v)
    for key=string(fieldnames(v))', if ~canonical(v.(key)), ok=false; return; end, end
end
end
