function result=antiRollBarStiffness(bar)
%ANTIROLLBARSTIFFNESS Declared port stiffness or circular Saint-Venant torsion.
r=fsd.model.antiRollBarReadiness(bar,'STIFFNESS'); p=bar.definition.parameters;
result=struct('status',r.status,'missing',r.missing,'kTheta_Nm_per_rad',NaN,'polarAreaMoment_m4',NaN, ...
    'scope',bar.definition.stiffnessScope,'assumptions',strings(0,1));
if r.status~="READY", return; end
if bar.definition.stiffnessMode=="KNOWN", result.kTheta_Nm_per_rad=p.kTheta_Nm_per_rad; return; end
inner=0; if bar.definition.section=="TUBULAR", inner=p.innerDiameter_m; end
J=pi*(p.outerDiameter_m^4-inner^4)/32; k=p.G_Pa*J/p.effectiveLength_m;
assert(isfinite(J)&&J>0&&isfinite(k)&&k>0,'fsd:analysis:InvalidAntiRollBar','Section arithmetic not representable.');
result.polarAreaMoment_m4=J; result.kTheta_Nm_per_rad=k; result.scope="SHAFT_ONLY";
result.assumptions=["Straight circular active span; linear elastic shear.";"No flexible arms/blades/supports or stress concentration model."];
end
