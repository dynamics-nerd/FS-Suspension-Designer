function result=evaluateAntiRollBarTorsion(bar,angles)
%EVALUATEANTIROLLBARTORSION Explicit angular pairs, no wheel/geometry inference.
r=fsd.model.antiRollBarReadiness(bar,'TORSION');
assert(r.status=="READY",'fsd:analysis:AntiRollBarNotReady',strjoin([r.status;r.missing],'; '));
assert(isnumeric(angles)&&isreal(angles)&&size(angles,2)==2&&~isempty(angles)&&all(isfinite(angles),'all'), ...
    'fsd:analysis:InvalidAntiRollBar','Finite N-by-2 arm angles required.');
p=bar.definition.parameters; free=p.freeAngle_rad;
if bar.definition.referenceMode=="ZERO_AT_INSTALLATION", free=p.installationAngles_rad(2)-p.installationAngles_rad(1); end
stiffness=fsd.analysis.antiRollBarStiffness(bar); psi=double(angles(:,2))-double(angles(:,1))-free;
available=psi>=p.twistDomain_rad(1)&psi<=p.twistDomain_rad(2);
T=stiffness.kTheta_Nm_per_rad*psi; U=.5*stiffness.kTheta_Nm_per_rad*psi.^2;
T(~available)=NaN; U(~available)=NaN;
status=repmat("AVAILABLE",size(psi)); status(~available)="OUT_OF_DOMAIN";
result=struct('kind',"AntiRollBarTorsionResponse",'barIdentity',bar.identity,'angles_rad',double(angles), ...
    'freeAngle_rad',free,'twist_rad',psi,'torque_Nm',T,'armTorques_Nm',[T,-T], ...
    'energy_J',U,'status',status,'stiffness',stiffness);
end
