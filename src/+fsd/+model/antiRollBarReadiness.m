function report=antiRollBarReadiness(bar,operation)
%ANTIROLLBARREADINESS Pure declaration checks; no kinematic or global solve.
fsd.model.validateAntiRollBar(bar); d=bar.definition; p=d.parameters; operation=string(operation);
assert(isscalar(operation)&&ismember(operation,["GEOMETRY","MECHANICAL","STIFFNESS","TORSION"]), ...
    'fsd:model:InvalidAntiRollBarOperation','Unknown ARB operation.');
missing=strings(0,1); status="READY"; keys=strings(0,1);
geometric=d.representation=="COAXIAL_TORSION";
if operation=="GEOMETRY"||operation=="MECHANICAL"
    if d.axleId=="UNSELECTED", missing(end+1)="AXLE:SELECT"; end
    keys(end+1)="wheelTravelDomain_m";
end
if operation=="GEOMETRY"||(operation=="MECHANICAL"&&geometric)
    if ~geometric, status="UNSUPPORTED";
    else
        if isempty(d.referenceFrame), missing(end+1)="FRAME:DECLARE_NATIVE_FRAME"; end
        keys=[keys,"axisPoint_m","axisDirection_unit","armPoints_m", ...
            "linkLengths_m","driverPoints_m","installationAngles_rad","armAngleDomain_rad"];
        if any(d.drivers=="UNSELECTED"), missing(end+1)="DRIVERS:SELECT_BOTH"; end
    end
end
if operation~="GEOMETRY"
    if geometric
        if d.stiffnessMode=="UNKNOWN", missing(end+1)="STIFFNESS:SELECT_ROUTE";
        elseif d.stiffnessMode=="KNOWN"
            keys(end+1)="kTheta_Nm_per_rad";
            if d.stiffnessScope=="UNKNOWN", missing(end+1)="STIFFNESS:DECLARE_PORT_SCOPE"; end
        else
            keys=[keys,"G_Pa","outerDiameter_m","effectiveLength_m"];
            if d.section=="UNKNOWN", missing(end+1)="SECTION:SELECT";
            elseif d.section=="TUBULAR"
                keys(end+1)="innerDiameter_m";
                if ~isempty(p.innerDiameter_m)&&p.innerDiameter_m==0, missing(end+1)="SECTION:TUBULAR_REQUIRES_HOLE"; end
            end
        end
    elseif ismember(operation,["STIFFNESS","TORSION"]), status="UNSUPPORTED";
    else, keys=[keys,"weights","linearStiffness_N_per_m","deflectionDomain_m"];
    end
    if operation~="STIFFNESS"
        if d.referenceMode=="UNKNOWN", missing(end+1)="REFERENCE:DECLARE_FREE_CONDITION";
        elseif d.referenceMode=="ZERO_AT_INSTALLATION"
            if geometric, keys(end+1)="installationAngles_rad"; else, keys(end+1)="installationWheelTravel_m"; end
        else
            if geometric, keys(end+1)="freeAngle_rad"; else, keys(end+1)="freeDeflection_m"; end
        end
        if geometric, keys(end+1)="twistDomain_rad"; end
    end
end
if geometric&&ismember(operation,["GEOMETRY","MECHANICAL"])&&~isempty(p.armPoints_m)&&~isempty(p.driverPoints_m)&&~isempty(p.linkLengths_m)
    tol=fsd.model.numericTolerances(); residual=vecnorm(p.armPoints_m-p.driverPoints_m,2,2)-p.linkLengths_m;
    if any(abs(residual)>10*(tol.AbsTol_m+tol.RelTol*max([abs(p.armPoints_m(:));abs(p.driverPoints_m(:));1])))
        status="INVALID_INPUT"; missing(end+1)="INSTALLATION:LINK_LENGTH_MISMATCH";
    end
end
for key=reshape(unique(keys),1,[])
    if isempty(p.(key)), missing(end+1)="PARAMETER:"+key; end %#ok<AGROW> At most the fixed parameter catalog.
end
if status=="READY"&&~isempty(missing), status="MISSING_DATA"; end
report=struct('status',status,'missing',unique(missing(:)),'diagnostics',strings(0,1),'operation',operation);
end
