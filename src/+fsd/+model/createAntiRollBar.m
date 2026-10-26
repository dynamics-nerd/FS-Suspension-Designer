function bar=createAntiRollBar(input)
%CREATEANTIROLLBAR Canonical partial SI declaration; no inferred physical data.
d=struct('id',"",'name',"",'revision',1,'axleId',"UNSELECTED", ...
    'representation',"EQUIVALENT_LINEAR",'referenceMode',"UNKNOWN", ...
    'stiffnessMode',"UNKNOWN",'stiffnessScope',"UNKNOWN",'section',"UNKNOWN", ...
    'drivers',["UNSELECTED";"UNSELECTED"],'adjustmentId',"", ...
    'parameters',struct(),'provenance',struct(),'referenceFrame',[],'note',"");
need(isstruct(input)&&isscalar(input)&&all(ismember(string(fieldnames(input)),string(fieldnames(d)))),'Unknown ARB declaration fields.');
for key=string(fieldnames(input))', d.(key)=input.(key); end
for key=["id","name","axleId","representation","referenceMode","stiffnessMode","stiffnessScope","section","adjustmentId","note"]
    d.(key)=text(d.(key));
end
need(~isempty(regexp(d.id,'^[A-Z][A-Z0-9_]*$','once')),'Canonical ARB ID required.');
d.revision=number(d.revision); need(isscalar(d.revision)&&d.revision>=1&&fix(d.revision)==d.revision,'Positive integer revision required.');
need(ismember(d.axleId,["UNSELECTED","FRONT","REAR"]),'Unsupported axle.');
need(ismember(d.representation,["EQUIVALENT_LINEAR","COAXIAL_TORSION"]),'Unsupported ARB representation.');
need(ismember(d.referenceMode,["UNKNOWN","ZERO_AT_INSTALLATION","DECLARED_FREE"]),'Unknown free reference mode.');
need(ismember(d.stiffnessMode,["UNKNOWN","KNOWN","CIRCULAR_SHAFT"]),'Unknown constitutive route.');
need(ismember(d.stiffnessScope,["UNKNOWN","SHAFT_ONLY","EFFECTIVE_PORTS"]),'Unknown stiffness port scope.');
need(ismember(d.section,["UNKNOWN","SOLID","TUBULAR"]),'Unknown shaft section.');
need((isstring(d.drivers)||iscellstr(d.drivers))&&numel(d.drivers)==2,'Two driver body declarations required.');
d.drivers=string(d.drivers(:));
need(all(ismember(d.drivers,["UNSELECTED","ROCKER","UPRIGHT","UCA","LCA"])),'Unsupported driver body.');
if ~isempty(d.referenceFrame)
    f=d.referenceFrame;
    need(isstruct(f)&&isscalar(f)&&isequal(sort(string(fieldnames(f))),["axisConvention";"id";"originDescription"])&& ...
        string(f.axisConvention)=="X_REAR_Y_RIGHT_Z_UP",'Native complete coordinate frame required.');
    for key=string(fieldnames(f))', need(isscalar(string(f.(key)))&&~ismissing(string(f.(key)))&&strlength(string(f.(key)))>0,'Nonempty coordinate frame fields required.'); end
end
catalog=fsd.model.antiRollBarParameterCatalog(); keys=string({catalog.id});
need(isstruct(d.parameters)&&isscalar(d.parameters)&&all(ismember(string(fieldnames(d.parameters)),keys)),'Unknown parameter.');
need(isstruct(d.provenance)&&isscalar(d.provenance)&&all(ismember(string(fieldnames(d.provenance)),keys)),'Unknown parameter provenance.');
p=struct();
for k=1:numel(catalog)
    key=keys(k); v=[]; if isfield(d.parameters,key), v=d.parameters.(key); end
    v=number(v);
    if ~isempty(v)
        need(isequal(size(v),catalog(k).shape),'Parameter '+key+' has incompatible shape.');
        need(isfield(d.provenance,key),'Available parameter '+key+' needs provenance.');
    end
    p.(key)=v;
end
for key=string(fieldnames(d.provenance))'
    source=d.provenance.(key);
    need(isstruct(source)&&isscalar(source)&&isequal(sort(string(fieldnames(source))),["sourceKind";"sourceNote"]),'Invalid source fields.');
    source.sourceKind=text(source.sourceKind); source.sourceNote=text(source.sourceNote);
    need(ismember(source.sourceKind,["KNOWN","ASSUMED","DERIVED","FIXED"])&&strlength(source.sourceNote)>0,'Explicit source kind/note required.');
    d.provenance.(key)=source;
end
for key=["linearStiffness_N_per_m","linkLengths_m","kTheta_Nm_per_rad","G_Pa","outerDiameter_m","effectiveLength_m"]
    need(isempty(p.(key))||all(p.(key)>0,'all'),'Positive '+key+' required.');
end
need(isempty(p.innerDiameter_m)||p.innerDiameter_m>=0,'Inner diameter cannot be negative.');
if ~isempty(p.outerDiameter_m)&&~isempty(p.innerDiameter_m)
    need(p.innerDiameter_m<p.outerDiameter_m,'Inner diameter must be smaller than outer.');
end
need(isempty(p.weights)||all(p.weights~=0),'Equivalent coupling requires both nonzero displacement weights.');
if ~isempty(p.axisDirection_unit)
    need(norm(p.axisDirection_unit)>0,'Nonzero oriented axis required.');
    magnitude=norm(p.axisDirection_unit);
    if ~isfinite(magnitude)
        scaled=p.axisDirection_unit/max(abs(p.axisDirection_unit));
        p.axisDirection_unit=scaled/norm(scaled); magnitude=norm(p.axisDirection_unit);
    end
    if abs(magnitude-1)>8*eps, p.axisDirection_unit=p.axisDirection_unit/magnitude; end
end
for key=["wheelTravelDomain_m","armAngleDomain_rad","twistDomain_rad","deflectionDomain_m"]
    v=p.(key); need(isempty(v)||all(v(:,1)<v(:,2)),'Strictly ordered domain limits required.');
end
if d.stiffnessMode=="CIRCULAR_SHAFT", need(isempty(p.kTheta_Nm_per_rad),'Calculated and known stiffness routes cannot be active together.'); end
if d.representation=="COAXIAL_TORSION"&&~isempty(p.axisPoint_m)&&~isempty(p.axisDirection_unit)
    for key=["supports_m","armPoints_m"]
        v=p.(key); if isempty(v), continue; end
        radial=v-p.axisPoint_m-(v-p.axisPoint_m)*p.axisDirection_unit'*p.axisDirection_unit;
        tol=fsd.model.numericTolerances(); budget=tol.AbsTol_m+tol.RelTol*max([abs(v(:));1]);
        if key=="supports_m"
            need(all(vecnorm(radial,2,2)<=budget)&&norm(diff(v))>budget,'Distinct supports must lie on the declared axis.');
        else
            need(all(vecnorm(radial,2,2)>budget),'ARB arms need nondegenerate radii.');
        end
    end
end
d.parameters=p; identity=rmfield(d,{'name','note'});
bar=struct('schemaVersion',"0.23.0",'kind',"AntiRollBar",'units',"SI",'definition',d,'identity',identity);
end
function v=number(v)
need((isa(v,'double')||isa(v,'single')||isinteger(v))&&isreal(v)&&all(isfinite(v),'all'),'Real finite built-in numeric data required.');
if isinteger(v)
    x=double(v); need(all(abs(x)<=flintmax,'all')&&isequal(cast(x,'like',v),v),'Unsafe integer conversion.');
end
if isempty(v), v=[]; else, v=full(double(v)); end
end
function s=text(s)
need((isstring(s)&&isscalar(s)&&~ismissing(s))||(ischar(s)&&(isrow(s)||isempty(s))),'Scalar text required.'); s=string(s);
end
function need(ok,message)
assert(ok,'fsd:model:InvalidAntiRollBar',message);
end
