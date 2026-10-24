function [s,q]=evaluationInput(s,q)
%EVALUATIONINPUT Explicit column samples, scalar expansion, never a grid.
names=["Fz_N","alpha_rad","kappa","gamma_rad"];
assert(isstruct(s)&&isscalar(s)&&all(isfield(s,names))&&all(ismember(string(fieldnames(s)),names)), ...
    'fsd:tire:InvalidStates','Four explicit state channels required.');
n=1;
for name=names
    v=s.(name); assert(isnumeric(v)&&isreal(v)&&isvector(v)&&~isempty(v), ...
        'fsd:tire:InvalidStates','Nonempty real scalar/vector states required.');
    n=max(n,numel(v));
end
for name=names
    v=double(s.(name)); assert(isscalar(v)||numel(v)==n,'fsd:tire:InvalidStates','State lengths must match or be scalar.');
    if isscalar(v), v=repmat(v,n,1); end
    s.(name)=v(:);
end
q=fsd.tire.normalizeRequest(q);
end
