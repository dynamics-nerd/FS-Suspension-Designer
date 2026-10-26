function value=antiRollBarDependencies(bar,operation)
%ANTIROLLBARDEPENDENCIES Structural physical consumption, not execution identity.
fsd.model.validateAntiRollBar(bar); operation=string(operation);
assert(ismember(operation,["GEOMETRY","MECHANICAL","SIZING"]),'fsd:model:InvalidAntiRollBarOperation','Unknown dependency operation.');
d=bar.definition; p=d.parameters;
value=struct('kind',"AntiRollBarDependencies",'id',d.id,'axleId',d.axleId, ...
    'representation',d.representation,'adjustmentId',d.adjustmentId,'operation',operation,'parameters',struct(),'provenance',struct());
keys="wheelTravelDomain_m";
if operation=="SIZING"
    keys=["G_Pa","effectiveLength_m"]; value.section=d.section;
    if d.section=="TUBULAR", keys(end+1)="innerDiameter_m"; end
end
if d.representation=="COAXIAL_TORSION"&&operation~="SIZING"
    value.referenceFrame=d.referenceFrame;
    keys=[keys,"axisPoint_m","axisDirection_unit","armPoints_m","linkLengths_m", ...
        "driverPoints_m","installationAngles_rad","armAngleDomain_rad"];
    value.drivers=d.drivers;
end
if operation=="MECHANICAL"
    value.referenceMode=d.referenceMode;
    if d.representation=="EQUIVALENT_LINEAR"
        keys=[keys,"weights","linearStiffness_N_per_m","deflectionDomain_m"];
        if d.referenceMode=="ZERO_AT_INSTALLATION", keys(end+1)="installationWheelTravel_m";
        else, keys(end+1)="freeDeflection_m"; end
    else
        keys(end+1)="twistDomain_rad"; value.stiffnessMode=d.stiffnessMode;
        if d.stiffnessMode=="KNOWN"
            keys(end+1)="kTheta_Nm_per_rad"; value.stiffnessScope=d.stiffnessScope;
        elseif d.stiffnessMode=="CIRCULAR_SHAFT"
            keys=[keys,"G_Pa","outerDiameter_m","effectiveLength_m"]; value.section=d.section;
            if d.section=="TUBULAR", keys(end+1)="innerDiameter_m"; end
        end
        if d.referenceMode=="DECLARED_FREE", keys(end+1)="freeAngle_rad"; end
    end
end
for key=sort(unique(keys))
    value.parameters.(key)=p.(key);
    if isfield(d.provenance,key), value.provenance.(key)=d.provenance.(key); end
end
end
