function value=tireConfiguration(mode,input,previous)
%TIRECONFIGURATION Presentation boundary; mm/degrees converted only here.
if nargin<3, previous=[]; end
keys=["unloadedRadius_m","width_m","rimRadius_m","stiffness_N_per_m", ...
    "Fz0_N","mu0","Calpha_N_per_rad","Ckappa_N","Cgamma_N_per_rad","n","pAlpha","pKappa","qGamma_per_rad2"];
units=["mm","mm","mm","N/mm","N","1","N/rad","N","N/rad","1","1","1","1/rad^2"];
factors=[1000,1000,1000,.001,ones(1,9)];
laws=["capacityLoad","lateralLoad","longitudinalLoad","camberThrust","camberCapacity"];
if string(mode)=="ROWS"
    rows=struct('parameters',{[cellstr(keys(:)),repmat({''},13,1),cellstr(units(:)),repmat({''},13,2)]}, ...
        'domain',{[cellstr(["Fz [N]";"alpha [deg]";"kappa";"gamma [deg]"]),repmat({''},4,2)]}, ...
        'laws',{[cellstr(laws(:)),repmat({'UNSPECIFIED'},5,1)]});
    if isempty(input), value=rows; return; end
    d=input.definition; values=[struct2cell(d.geometry);struct2cell(d.vertical);struct2cell(d.force.parameters)];
    for k=1:13
        if ~isempty(values{k}), rows.parameters{k,2}=values{k}*factors(k); end
        if isfield(d.provenance,keys(k))
            p=d.provenance.(keys(k)); rows.parameters(k,4:5)={char(p.sourceKind),char(p.sourceNote)};
        end
    end
    names=["Fz_N","alpha_rad","kappa","gamma_rad"]; scales=[1,180/pi,1,180/pi];
    for k=1:4
        lim=d.force.domain.(names(k)); if ~isempty(lim), rows.domain(k,2:3)=num2cell(lim*scales(k)); end
    end
    for k=1:5, rows.laws{k,2}=char(d.force.(laws(k))); end
    value=rows; return;
end
assert(string(mode)=="DEFINITION",'fsd:ui:TireInput','Unknown conversion.');
r=input; d=struct(); if ~isempty(previous), d=previous.definition; end
originalRows=[]; if ~isempty(previous), originalRows=fsdui.tireConfiguration('ROWS',previous); end
d.id=string(r.id); d.name=string(r.name); d.level=string(r.level); d.evidence=string(r.evidence); d.note=string(r.note);
if ~isempty(previous)&&d.id~=previous.definition.id, d.revision=1; end
empty=fsd.tire.create(struct('id',d.id));
d.geometry=empty.definition.geometry; d.vertical=empty.definition.vertical; d.force=empty.definition.force;
d.force.family=string(r.family); d.provenance=struct();
for k=1:13
    assert(string(r.parameters{k,1})==keys(k),'fsd:ui:TireInput','Parameter order changed.');
    raw=r.parameters{k,2}; v=[];
    if strlength(string(raw))>0
        v=scalar(raw)/factors(k);
        if ~isempty(originalRows)&&isequaln(raw,originalRows.parameters{k,2})
            source=[struct2cell(previous.definition.geometry);struct2cell(previous.definition.vertical);struct2cell(previous.definition.force.parameters)];
            v=source{k};
        end
        d.provenance.(keys(k))=struct('sourceKind',string(r.parameters{k,4}),'sourceNote',string(r.parameters{k,5}));
    end
    if k<=3, d.geometry.(keys(k))=v;
    elseif k==4, d.vertical.(keys(k))=v;
    else, d.force.parameters.(keys(k))=v;
    end
end
names=["Fz_N","alpha_rad","kappa","gamma_rad"]; scales=[1,180/pi,1,180/pi];
for k=1:4
    cells=r.domain(k,2:3); blank=cellfun(@(x)strlength(string(x))==0,cells);
    if all(blank), d.force.domain.(names(k))=[];
    else
        assert(~any(blank),'fsd:ui:TireInput','Supply both domain limits or leave both blank.');
        d.force.domain.(names(k))=[scalar(cells{1}),scalar(cells{2})]/scales(k);
        if ~isempty(originalRows)&&isequaln(cells,originalRows.domain(k,2:3)), d.force.domain.(names(k))=previous.definition.force.domain.(names(k)); end
    end
end
for k=1:5, d.force.(laws(k))=string(r.laws{k,2}); end
value=d;
end
function v=scalar(v)
if ~isnumeric(v), v=str2double(string(v)); end
assert(isnumeric(v)&&isreal(v)&&isscalar(v)&&isfinite(v),'fsd:ui:TireInput','Finite number required; blank means unknown.'); v=double(v);
end
