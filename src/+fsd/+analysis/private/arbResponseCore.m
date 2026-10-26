function r=arbResponseCore(prepared,z)
%ARBRESPONSECORE One energy and exact derivatives of its declared coordinate.
d=prepared.bar.definition; p=d.parameters;
r=struct('schemaVersion',"0.23.0",'kind',"AntiRollBarResponse",'barIdentity',prepared.identity, ...
    'wheelTravel_m',z,'status',prepared.readiness.status,'missing',prepared.readiness.missing, ...
    'available',false,'diagnostics',strings(0,1),'representation',d.representation, ...
    'energy_J',NaN,'resistance_N',nan(2,1),'appliedGeneralizedForce_N',nan(2,1), ...
    'tangent_N_per_m',nan(2),'elasticTangent_N_per_m',nan(2),'geometricTangent_N_per_m',nan(2), ...
    'candidateTangent_N_per_m',nan(2),'tangentStatus',"UNAVAILABLE", ...
    'deformation_m',NaN,'twist_rad',NaN,'torque_Nm',NaN,'armTorques_Nm',nan(2,1), ...
    'armAngles_rad',nan(2,1),'angleFirst_per_m',nan(2,1),'angleSecond_per_m2',nan(2,1), ...
    'driverPoints_m',nan(2,3),'armPoints_m',nan(2,3),'linkForces_N',nan(2,1), ...
    'driverForces_N',nan(2,3),'segmentIds',zeros(2,1),'branchSigns',zeros(2,1), ...
    'closureEnds',{{}}, ...
    'bilateralCurvatureAvailable',false,'approximation',"DECLARED_EQUIVALENT_COORDINATE");
if prepared.readiness.status~="READY", return; end
if any(~isfinite(z)), r.status="INVALID_INPUT"; r.diagnostics="Unavailable native motion coordinates retained."; return; end
if any(z<p.wheelTravelDomain_m(:,1)|z>p.wheelTravelDomain_m(:,2))
    r.status="OUT_OF_DOMAIN"; r.diagnostics="Wheel coordinate outside declared domain."; return;
end
if d.representation=="EQUIVALENT_LINEAR"
    free=p.freeDeflection_m;
    if d.referenceMode=="ZERO_AT_INSTALLATION", free=p.weights'*p.installationWheelTravel_m; end
    x=p.weights'*z-free; a=p.weights; curvature=zeros(2); k=p.linearStiffness_N_per_m;
    r.deformation_m=x;
    if x<p.deflectionDomain_m(1)||x>p.deflectionDomain_m(2), r.status="OUT_OF_DOMAIN"; return; end
    r.bilateralCurvatureAvailable=true;
else
    coordinate=arbCoordinateCore(prepared,z); r.segmentIds=coordinate.segmentIds; r.closureEnds=coordinate.ends;
    if ~coordinate.available, r.status=coordinate.status; return; end
    r.armAngles_rad=coordinate.angles_rad; r.angleFirst_per_m=coordinate.first_per_m;
    r.angleSecond_per_m2=coordinate.second_per_m2; r.driverPoints_m=coordinate.driverPoints_m;
    r.armPoints_m=coordinate.armPoints_m; r.branchSigns=coordinate.branchSigns;
    free=p.freeAngle_rad;
    if d.referenceMode=="ZERO_AT_INSTALLATION", free=p.installationAngles_rad(2)-p.installationAngles_rad(1); end
    x=diff(r.armAngles_rad)-free; a=[-r.angleFirst_per_m(1);r.angleFirst_per_m(2)];
    curvature=diag([-r.angleSecond_per_m2(1),r.angleSecond_per_m2(2)]);
    k=prepared.stiffness.kTheta_Nm_per_rad; r.twist_rad=x;
    r.approximation="SAMPLED_DRIVER_PATH_APPROXIMATION";
    if x<p.twistDomain_rad(1)||x>p.twistDomain_rad(2), r.status="TWIST_LIMIT"; return; end
    r.torque_Nm=k*x; r.armTorques_Nm=[r.torque_Nm;-r.torque_Nm];
    r.bilateralCurvatureAvailable=coordinate.bilateralCurvatureAvailable;
    r.bilateralCurvatureAvailable=r.bilateralCurvatureAvailable&& ...
        all(r.armAngles_rad>p.armAngleDomain_rad(:,1)&r.armAngles_rad<p.armAngleDomain_rad(:,2));
    for side=1:2
        direction=(r.driverPoints_m(side,:)-r.armPoints_m(side,:))/p.linkLengths_m(side);
        lever=dot(p.axisDirection_unit,cross(r.armPoints_m(side,:)-p.axisPoint_m,direction));
        r.linkForces_N(side)=-r.armTorques_Nm(side)/lever;
        r.driverForces_N(side,:)=-r.linkForces_N(side)*direction;
    end
end
boundary=64*eps(max([abs(z);1]));
r.bilateralCurvatureAvailable=r.bilateralCurvatureAvailable&& ...
    all(z>p.wheelTravelDomain_m(:,1)+boundary&z<p.wheelTravelDomain_m(:,2)-boundary);
domain=p.deflectionDomain_m; if d.representation=="COAXIAL_TORSION", domain=p.twistDomain_rad; end
r.bilateralCurvatureAvailable=r.bilateralCurvatureAvailable&&x>domain(1)&&x<domain(2);
T=k*x; r.energy_J=.5*k*x^2; r.resistance_N=T*a; r.appliedGeneralizedForce_N=-r.resistance_N;
r.elasticTangent_N_per_m=k*(a*a'); r.geometricTangent_N_per_m=T*curvature;
r.tangent_N_per_m=r.elasticTangent_N_per_m+r.geometricTangent_N_per_m;
r.candidateTangent_N_per_m=r.tangent_N_per_m;
numeric=[r.energy_J;r.resistance_N;r.tangent_N_per_m(:)];
if d.representation=="COAXIAL_TORSION", numeric=[numeric;r.torque_Nm;r.linkForces_N;r.driverForces_N(:)]; end
if any(~isfinite(numeric))
    r.status="NUMERICALLY_UNRESOLVED"; r.energy_J=NaN; r.resistance_N(:)=NaN;
    r.appliedGeneralizedForce_N(:)=NaN; r.tangent_N_per_m(:)=NaN;
    r.candidateTangent_N_per_m(:)=NaN; r.elasticTangent_N_per_m(:)=NaN; r.geometricTangent_N_per_m(:)=NaN;
    r.linkForces_N(:)=NaN; r.driverForces_N(:)=NaN; r.torque_Nm=NaN; r.armTorques_Nm(:)=NaN; return;
end
r.status="AVAILABLE"; r.available=true; r.tangentStatus="AVAILABLE";
if ~r.bilateralCurvatureAvailable, r.tangent_N_per_m(:)=NaN; r.tangentStatus="BILATERAL_CURVATURE_UNAVAILABLE"; end
end
