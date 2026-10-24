function projection=evaluationDependencies(tire,states,request)
%EVALUATIONDEPENDENCIES Structural consumption proof, not output-array equality.
% Full execution identity remains with the caller; this is only for reuse.
fsd.tire.validate(tire); [s,q]=evaluationInput(states,request);
d=tire.definition; f=d.force;
projection=struct('variant',"TIRE_CONSUMPTION_1",'tireId',d.id,'states',s,'request',q);
if f.family~="DUGOFF_REDUCED_1"||any(q.channels=="Mz")
    % Unsupported/future models have no proven selective dependency contract.
    projection.conservativeIdentity=rmfield(tire.identity,'revision'); return;
end
keys="mu0"; modes=f.capacityLoad;
consumed=struct('family',f.family,'domain',f.domain,'capacityLoad',f.capacityLoad);
lateral=any(q.channels=="Fy")||any(s.alpha_rad~=0);
longitudinal=any(q.channels=="Fx")||any(s.kappa~=0);
if f.capacityLoad=="POWER", keys(end+1)="n"; end
if lateral
    consumed.lateralLoad=f.lateralLoad; modes(end+1)=f.lateralLoad;
    keys(end+1)="Calpha_N_per_rad";
    if f.lateralLoad=="POWER", keys(end+1)="pAlpha"; end
end
if longitudinal
    consumed.longitudinalLoad=f.longitudinalLoad; modes(end+1)=f.longitudinalLoad;
    keys(end+1)="Ckappa_N";
    if f.longitudinalLoad=="POWER", keys(end+1)="pKappa"; end
end
if any(ismember(modes,["REFERENCE_ONLY","POWER"])), keys(end+1)="Fz0_N"; end
if any(s.gamma_rad~=0)
    consumed.camberThrust=f.camberThrust; consumed.camberCapacity=f.camberCapacity;
    if f.camberThrust=="LINEAR_CONSTANT", keys(end+1)="Cgamma_N_per_rad"; end
    if f.camberCapacity=="QUADRATIC", keys(end+1)="qGamma_per_rad2"; end
end
consumed.parameters=struct(); consumed.provenance=struct();
for key=sort(unique(keys))
    consumed.parameters.(key)=f.parameters.(key);
    if isfield(d.provenance,key), consumed.provenance.(key)=d.provenance.(key); end
end
projection.force=consumed;
% Response quality is conservative over the declaration, even unused sources.
assumed=false;
for key=string(fieldnames(d.provenance))', assumed=assumed||d.provenance.(key).sourceKind=="ASSUMED"; end
projection.assumptionBased=assumed||ismember("NEGLECTED",[f.camberThrust,f.camberCapacity])|| ...
    ismember("CONSTANT",[f.lateralLoad,f.longitudinalLoad])||f.capacityLoad=="CONSTANT_MU";
projection.evidence=d.evidence;
if ismember(d.evidence,["CALIBRATED","VALIDATED"]), projection.evidenceReference=d.note; end
end
