function r=responseCore(tire,s,q)
%RESPONSECORE Prevalidated stationary Dugoff variant with explicit extensions.
d=tire.definition; f=d.force; p=f.parameters; n=numel(s.Fz_N); channels=["Fx","Fy","Mz"];
values=nan(n,3); status=repmat("NOT_REQUESTED",n,3); diagnostic=strings(n,3);
assumed=false;
for name=string(fieldnames(d.provenance))', assumed=assumed||d.provenance.(name).sourceKind=="ASSUMED"; end
assumed=assumed||ismember("NEGLECTED",[f.camberThrust,f.camberCapacity])|| ...
    ismember("CONSTANT",[f.lateralLoad,f.longitudinalLoad])||f.capacityLoad=="CONSTANT_MU";
for j=1:3
    if ~ismember(channels(j),q.channels), continue; end
    status(:,j)="AVAILABLE";
    if j==3||f.family=="NONE", status(:,j)="NOT_SUPPORTED"; continue; end
    for k=1:n
        z=s.Fz_N(k); a=s.alpha_rad(k); b=s.kappa(k); g=s.gamma_rad(k);
        if any(~isfinite([z,a,b,g]))||z<0||abs(a)>=pi/2||abs(g)>=pi/2||b<=-1
            status(k,j)="INVALID_INPUT"; diagnostic(k,j)="Finite states, Fz >= 0, |angles| < pi/2 and kappa > -1 required."; continue;
        end
        missing=strings(0,1); outside=false;
        for name=["Fz_N","alpha_rad","kappa","gamma_rad"]
            lim=f.domain.(name);
            if isempty(lim), missing(end+1)="DOMAIN:"+name; %#ok<AGROW>
            elseif s.(name)(k)<lim(1)||s.(name)(k)>lim(2), outside=true;
            end
        end
        lateral=(j==2)||a~=0; longitudinal=(j==1)||b~=0;
        [capacity,m,o]=law(p,f.capacityLoad,'mu0','n',z,true); missing=[missing;m]; outside=outside||o; %#ok<AGROW> Bounded missing-field diagnostics.
        ca=0; ck=0;
        if lateral, [ca,m,o]=law(p,f.lateralLoad,'Calpha_N_per_rad','pAlpha',z,false); missing=[missing;m]; outside=outside||o; end %#ok<AGROW> Bounded missing-field diagnostics.
        if longitudinal, [ck,m,o]=law(p,f.longitudinalLoad,'Ckappa_N','pKappa',z,false); missing=[missing;m]; outside=outside||o; end %#ok<AGROW> Bounded missing-field diagnostics.
        cg=0; factor=1;
        if g~=0
            switch f.camberThrust
                case "UNSPECIFIED", missing(end+1)="CAMBER:THRUST"; %#ok<AGROW> Bounded missing-field diagnostics.
                case "LINEAR_CONSTANT"
                    if isempty(p.Cgamma_N_per_rad), missing(end+1)="PARAMETER:Cgamma_N_per_rad"; else, cg=p.Cgamma_N_per_rad; end %#ok<AGROW> Bounded missing-field diagnostics.
            end
            switch f.camberCapacity
                case "UNSPECIFIED", missing(end+1)="CAMBER:CAPACITY"; %#ok<AGROW> Bounded missing-field diagnostics.
                case "QUADRATIC"
                    if isempty(p.qGamma_per_rad2), missing(end+1)="PARAMETER:qGamma_per_rad2"; else, factor=1-p.qGamma_per_rad2*g^2; outside=outside||factor<=0; end %#ok<AGROW> Bounded missing-field diagnostics.
            end
        end
        if ~isempty(missing), status(k,j)="MISSING_DATA"; diagnostic(k,j)=join(unique(missing),' | '); continue; end
        if outside, status(k,j)="OUT_OF_DOMAIN"; diagnostic(k,j)="Declared domain/reference load or positive camber capacity factor exceeded."; continue; end
        if z==0, values(k,j)=0; status(k,j)="NO_CONTACT"; continue; end
        L=capacity*factor;
        dx=ck*b/(1+b); dy=(-ca*tan(a)+cg*g)/(1+b); radius=hypot(dx,dy);
        if ~all(isfinite([L,dx,dy,radius]))||L<=0
            status(k,j)="NUMERICALLY_UNRESOLVED"; diagnostic(k,j)="Nonfinite law/demand; no silent clipping."; continue;
        end
        demand=[dx,dy];
        if radius==0, force=[0,0];
        elseif radius<=L/2, force=demand;
        else
            % Algebraic lambda(2-lambda), arranged to avoid large demand*f.
            force=(demand/radius)*L*(1-L/(4*radius));
        end
        values(k,j)=force(j);
    end
end
quality=repmat("NOT_AVAILABLE",n,3);
quality(status=="AVAILABLE")="DECLARED_MODEL";
if assumed, quality(status=="AVAILABLE")="ASSUMPTION_BASED"; end
quality(status=="NO_CONTACT")="PHYSICAL_ZERO";
r=struct('schemaVersion',"0.22.0",'kind',"TireResponse",'modelIdentity',tire.identity, ...
    'family',f.family,'units',"SI",'frame',"CONTACT_FORWARD_LEFT_UP",'states',s,'request',q, ...
    'channels',channels,'Fx_N',values(:,1),'Fy_N',values(:,2),'Mz_Nm',values(:,3), ...
    'status',status,'quality',quality,'diagnostics',diagnostic,'provenance',d.provenance,'evidence',d.evidence, ...
    'assumptionBased',assumed,'domain',f.domain,'uncertainty',[]);
end
function [v,missing,outside]=law(p,mode,key,exponent,z,capacity)
v=NaN; missing=strings(0,1); outside=false;
if isempty(p.(key)), missing(end+1)="PARAMETER:"+key; end
if mode=="UNSPECIFIED", missing(end+1)="LOAD_LAW:"+key; end
if ismember(mode,["REFERENCE_ONLY","POWER"])&&isempty(p.Fz0_N), missing(end+1)="PARAMETER:Fz0_N"; end
if mode=="POWER"&&isempty(p.(exponent)), missing(end+1)="PARAMETER:"+exponent; end
if ~isempty(missing), return; end
v=p.(key);
if mode=="REFERENCE_ONLY", outside=z~=p.Fz0_N && z~=0;
elseif mode=="POWER"&&z>0
    power=p.(exponent); if capacity, power=power-1; end
    v=v*(z/p.Fz0_N)^power;
end
if capacity, v=v*z; end
end
