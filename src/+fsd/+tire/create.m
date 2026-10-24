function tire=create(input)
%CREATE SI, plain-value tire declaration; unknown physical values stay empty.
d=struct('id',"",'name',"",'revision',1,'level',"GEOMETRY_ONLY", ...
    'geometry',struct(),'vertical',struct(),'force',struct(),'provenance',struct(), ...
    'evidence',"USER_DECLARED",'note',"");
require(isstruct(input)&&isscalar(input)&&all(ismember(string(fieldnames(input)),string(fieldnames(d)))),'Unknown tire fields.');
for n=string(fieldnames(input))', d.(n)=input.(n); end
for n=["id","name","level","evidence","note"], d.(n)=scalarText(d.(n)); end
require(~isempty(regexp(d.id,'^[A-Z][A-Z0-9_]*$','once')),'Canonical tire ID required.');
d.revision=canonicalNumber(d.revision);
require(isnumeric(d.revision)&&isscalar(d.revision)&&isfinite(d.revision)&&d.revision>=1&&fix(d.revision)==d.revision,'Positive integer revision required.');
require(ismember(d.level,["GEOMETRY_ONLY","GENERIC","CUSTOM"]),'Unknown information level.');
require(ismember(d.evidence,["USER_DECLARED","ASSUMPTION_BASED","CALIBRATED","VALIDATED"]),'Unknown evidence quality.');
d.geometry=fill(d.geometry,struct('unloadedRadius_m',[],'width_m',[],'rimRadius_m',[]));
d.vertical=fill(d.vertical,struct('stiffness_N_per_m',[]));
params=struct('Fz0_N',[],'mu0',[],'Calpha_N_per_rad',[],'Ckappa_N',[], ...
    'Cgamma_N_per_rad',[],'n',[],'pAlpha',[],'pKappa',[],'qGamma_per_rad2',[]);
domain=struct('Fz_N',[],'alpha_rad',[],'kappa',[],'gamma_rad',[]);
f=fill(d.force,struct('family',"NONE",'parameters',struct(),'domain',struct(), ...
    'capacityLoad',"UNSPECIFIED",'lateralLoad',"UNSPECIFIED",'longitudinalLoad',"UNSPECIFIED", ...
    'camberThrust',"UNSPECIFIED",'camberCapacity',"UNSPECIFIED"));
f.parameters=fill(f.parameters,params); f.domain=fill(f.domain,domain);
% One public numeric boundary: no integer arithmetic reaches model evaluation.
for component=["geometry","vertical"]
    for n=string(fieldnames(d.(component)))'
        d.(component).(n)=canonicalNumber(d.(component).(n));
    end
end
for component=["parameters","domain"]
    for n=string(fieldnames(f.(component)))'
        f.(component).(n)=canonicalNumber(f.(component).(n));
    end
end
for n=["family","capacityLoad","lateralLoad","longitudinalLoad","camberThrust","camberCapacity"], f.(n)=scalarText(f.(n)); end
require(ismember(f.family,["NONE","DUGOFF_REDUCED_1"]),'Unsupported native family.');
require(ismember(f.capacityLoad,["UNSPECIFIED","REFERENCE_ONLY","CONSTANT_MU","POWER"]),'Invalid capacity load law.');
for n=["lateralLoad","longitudinalLoad"]
    require(ismember(f.(n),["UNSPECIFIED","REFERENCE_ONLY","CONSTANT","POWER"]),'Invalid stiffness load law.');
end
require(ismember(f.camberThrust,["UNSPECIFIED","NEGLECTED","LINEAR_CONSTANT"]),'Invalid camber thrust law.');
require(ismember(f.camberCapacity,["UNSPECIFIED","NEGLECTED","QUADRATIC"]),'Invalid camber capacity law.');
require(isstruct(d.provenance)&&isscalar(d.provenance),'Provenance must be a struct.');
values=[struct2cell(d.geometry);struct2cell(d.vertical);struct2cell(f.parameters)];
names=[string(fieldnames(d.geometry));string(fieldnames(d.vertical));string(fieldnames(params))];
require(all(ismember(string(fieldnames(d.provenance)),names)),'Unknown provenance parameter.');
for k=1:numel(values)
    v=values{k}; require(isnumeric(v)&&isreal(v)&&(isempty(v)||(isscalar(v)&&isfinite(v))),'Empty or finite scalar parameter required.');
    if isempty(v), continue; end
    if ~ismember(names(k),["Cgamma_N_per_rad","pAlpha","pKappa","qGamma_per_rad2"]), require(v>0,'Positive parameter required.'); end
    if names(k)=="qGamma_per_rad2", require(v>=0,'Nonnegative camber capacity coefficient required.'); end
    require(isfield(d.provenance,names(k)),'Every available parameter needs provenance.');
end
for n=string(fieldnames(d.provenance))'
    p=d.provenance.(n); require(isstruct(p)&&isscalar(p)&&isequal(sort(string(fieldnames(p))),["sourceKind";"sourceNote"]),'Invalid parameter provenance.');
    p.sourceKind=scalarText(p.sourceKind); p.sourceNote=scalarText(p.sourceNote);
    require(ismember(p.sourceKind,["KNOWN","ASSUMED","DERIVED"])&&strlength(p.sourceNote)>0,'Explicit source kind/note required.');
    d.provenance.(n)=p;
end
for n=string(fieldnames(domain))'
    v=f.domain.(n); require(isnumeric(v)&&isreal(v)&&(isempty(v)||(isequal(size(v),[1,2])&&all(isfinite(v))&&v(1)<=v(2))),'Domain must be empty or finite ordered pair.');
end
if ~isempty(f.domain.Fz_N), require(f.domain.Fz_N(1)>=0,'Negative normal load domain.'); end
if ~isempty(f.domain.kappa), require(f.domain.kappa(1)>-1,'DUGOFF_REDUCED_1 requires kappa > -1.'); end
for n=["alpha_rad","gamma_rad"]
    if ~isempty(f.domain.(n)), require(all(abs(f.domain.(n))<pi/2),'Angular domain must lie inside (-pi/2,pi/2).'); end
end
if ~isempty(d.geometry.rimRadius_m)&&~isempty(d.geometry.unloadedRadius_m)
    require(d.geometry.rimRadius_m<d.geometry.unloadedRadius_m,'Rim radius must be smaller than unloaded radius.');
end
d.force=f;
if ismember(d.evidence,["CALIBRATED","VALIDATED"]), require(strlength(d.note)>0,'Evidence reference required; quality is a declaration, not certification.'); end
vertical=struct('geometryRadius_m',d.geometry.unloadedRadius_m,'stiffness_N_per_m',d.vertical.stiffness_N_per_m,'provenance',struct());
for n=["unloadedRadius_m","stiffness_N_per_m"]
    if isfield(d.provenance,n), vertical.provenance.(n)=d.provenance.(n); end
end
identity=d; identity=rmfield(identity,{'name','note'});
tire=struct('schemaVersion',"0.22.0",'kind',"TireDefinition",'units',"SI",'definition',d, ...
    'identity',identity,'verticalIdentity',vertical);
end
function out=fill(in,out)
require(isstruct(in)&&isscalar(in)&&all(ismember(string(fieldnames(in)),string(fieldnames(out)))),'Unknown component field.');
for n=string(fieldnames(in))', out.(n)=in.(n); end
end
function s=scalarText(s)
require((isstring(s)&&isscalar(s)&&~ismissing(s))||(ischar(s)&&(isrow(s)||isempty(s))),'Scalar text required.'); s=string(s);
end
function v=canonicalNumber(v)
require((isa(v,'double')||isa(v,'single')||isinteger(v))&&isreal(v),'Real built-in numeric data required.');
require(all(isfinite(v),'all'),'Nonfinite numeric declarations are not admitted.');
if isinteger(v)
    x=double(v);
    require(all(abs(x)<=flintmax,'all')&&isequal(cast(x,'like',v),v), ...
        'Integer declarations must be exactly representable within double flintmax.');
end
if isempty(v), v=[]; else, v=full(double(v)); end
end
function require(ok,message)
assert(ok,'fsd:tire:InvalidDefinition',message);
end
