function equal=samePlainValue(a,b)
%SAMEPLAINVALUE Exact data/representation equality, without recursive ISEQUALN.
% Compare data once in the native implementation. Then check representation:
% classes, shapes, struct order, sparse/complex flags and floating-point bits.
equal=isequaln(a,b) && sameLayout(a,b);
end
function equal=sameLayout(a,b)
equal=strcmp(class(a),class(b)) && isequal(size(a),size(b));
if ~equal, return; end
if isstruct(a)
    equal=isequal(fieldnames(a),fieldnames(b)) && members(struct2cell(a),struct2cell(b));
elseif iscell(a)
    equal=members(a,b);
elseif isnumeric(a) || islogical(a)
    equal=numericLayout(a,b);
end
end
function equal=members(a,b)
classesA=cellfun(@class,a,'UniformOutput',false);
classesB=cellfun(@class,b,'UniformOutput',false);
equal=isequal(classesA,classesB); if ~equal, return; end
containers=cellfun('isclass',a,'struct') | cellfun('isclass',a,'cell');
numeric=cellfun(@isnumeric,a) | cellfun(@islogical,a);
indices=find(containers);
for k=indices(:)'
    if ~sameLayout(a{k},b{k}), equal=false; return; end
end
indices=find(numeric);
for k=indices(:)'
    if ~numericLayout(a{k},b{k}), equal=false; return; end
end
end
function equal=numericLayout(a,b)
equal=issparse(a)==issparse(b) && isreal(a)==isreal(b);
if ~equal || ~isfloat(a), return; end
if issparse(a), [~,~,a]=find(a); [~,~,b]=find(b); end
equal=isequal(typecast(real(a(:)),'uint8'),typecast(real(b(:)),'uint8')) && ...
    isequal(typecast(imag(a(:)),'uint8'),typecast(imag(b(:)),'uint8'));
end
