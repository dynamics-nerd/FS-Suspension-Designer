function value=arbConfiguration(mode,input,previous)
%ARBCONFIGURATION Presentation-only engineering-unit boundary; no model physics.
if nargin<3, previous=[]; end
catalog=fsd.model.antiRollBarParameterCatalog(); keys=string({catalog.id});
factors=[1,.001,1000,1000,1000,1,1000,1000,1000,1000, ...
    180/pi,180/pi,pi/180,1e-9,1000,1000,1000,1000,180/pi,180/pi,1000];
units=["1","N/mm","mm","mm","mm","1","mm","mm","mm","mm", ...
    "deg","deg","N*m/deg","GPa","mm","mm","mm","mm","deg","deg","mm"];
if string(mode)=="ROWS"
    rows=[cellstr(keys(:)),repmat({''},numel(keys),1),cellstr(units(:)),repmat({''},numel(keys),2)];
    if ~isempty(input)
        for k=1:numel(keys)
            v=input.definition.parameters.(keys(k)); if ~isempty(v), rows{k,2}=mat2str(v*factors(k),17); end
            if isfield(input.definition.provenance,keys(k))
                s=input.definition.provenance.(keys(k)); rows(k,4:5)={char(s.sourceKind),char(s.sourceNote)};
            end
        end
    end
    value=rows; return;
elseif string(mode)=="SAMPLES"
    left=fsdui.numberList(input{1}); right=fsdui.numberList(input{2}); n=max(numel(left),numel(right));
    assert(~isempty(left)&&~isempty(right)&&(isscalar(left)||numel(left)==n)&&(isscalar(right)||numel(right)==n), ...
        'fsd:ui:ArbInput','Supply matching left/right lists or a scalar expansion, never a grid.');
    if isscalar(left), left=repmat(left,n,1); end
    if isscalar(right), right=repmat(right,n,1); end
    value=[left(:),right(:)]/1000; return;
end
assert(string(mode)=="DEFINITION",'fsd:ui:ArbInput','Unknown conversion.');
r=input; d=struct(); if ~isempty(previous), d=previous.definition; end
for key=["id","name","axleId","representation","referenceMode","stiffnessMode","stiffnessScope","section","adjustmentId","note"]
    d.(key)=string(r.(key));
end
d.drivers=string(r.drivers(:)); d.referenceFrame=r.referenceFrame;
if ~isempty(previous)&&d.id~=previous.definition.id, d.revision=1; end
d.parameters=struct(); d.provenance=struct(); old=[];
if ~isempty(previous), old=fsdui.arbConfiguration('ROWS',previous); end
for k=1:numel(keys)
    assert(string(r.parameters{k,1})==keys(k),'fsd:ui:ArbInput','Parameter order changed.');
    raw=r.parameters{k,2}; v=[];
    if strlength(string(raw))>0
        v=parse(raw,catalog(k).shape)/factors(k);
        if ~isempty(old)&&isequaln(raw,old{k,2}), v=previous.definition.parameters.(keys(k)); end
    end
    d.parameters.(keys(k))=v;
    kind=string(r.parameters{k,4}); note=string(r.parameters{k,5});
    if ~isempty(v)||strlength(kind)>0||strlength(note)>0
        d.provenance.(keys(k))=struct('sourceKind',kind,'sourceNote',note);
    end
end
value=d;
end
function v=parse(raw,shape)
if isnumeric(raw), values=double(raw); values=reshape(values',[],1);
else
    text=regexprep(string(raw),'[\[\];,]',' '); values=fsdui.numberList(text);
end
assert(numel(values)==prod(shape),'fsd:ui:ArbInput','Expected numeric array shape %s; enter rows separated by semicolons.',mat2str(shape));
v=reshape(values,fliplr(shape))';
end
