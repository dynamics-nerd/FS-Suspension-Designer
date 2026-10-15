function [geometry,frame,derivations] = seedCornerCore(corner,parameters,references)
%SEEDCORNERCORE Documented reference offsets transformed rigidly as one body.
corner=string(corner); s=1; if ismember(corner,["FL","RL"]), s=-1; end
[wb,~]=seedReferenceValue(references,'WHEELBASE'); trackId="FRONT_TRACK"; x=0;
if ismember(corner,["RL","RR"]), x=wb; trackId="REAR_TRACK"; end
[track,~]=seedReferenceValue(references,trackId); C=[x,s*track/2,0];
v=struct(); for j=1:numel(parameters), p=parameters{j}.definitionSI; v.(p.id)=p.value; end
t=v.NOMINAL_TOE; c=v.NOMINAL_CAMBER;
alpha=-s*atan(tan(c)*cos(t)); R0=fsd.geometry.rotationMatrixAboutAxis([0,0,1],s*t)*fsd.geometry.rotationMatrixX(alpha);
axis=(R0*[0;s;0])'; axis=axis/norm(axis);
R=fsd.geometry.rotationMatrixAboutAxis(axis,-s*v.UPRIGHT_CLOCKING)*R0;
down=fsd.geometry.geometricWheelContact([0,0,0],axis,v.WHEEL_EFFECTIVE_RADIUS);
seedRequire(down.status=="FINITE",'DEGENERATE_WHEEL_REFERENCE'); WC=C-down.point_m;
local=zeros(3,3); names=["UBJ","LBJ","TIE_OUT"];
for j=1:3, prefix=names(j); local(j,:)=[v.(prefix+"_X"),s*v.(prefix+"_OUTBOARD"),v.(prefix+"_Z")]; end
upright=fsd.geometry.transformPointsRigid(local,[0,0,0],WC,R);
xyz=zeros(10,3); xyz(3,:)=upright(1,:); xyz(6,:)=upright(2,:); xyz(8,:)=upright(3,:); xyz(9,:)=WC; xyz(10,:)=C;
rows=[1,4];
for j=1:2
    arm="UCA"; ball=upright(1,:); if j==2, arm="LCA"; ball=upright(2,:); end
    midpoint=[C(1)+v.(arm+"_CENTER_X"),s*v.(arm+"_LATERAL"),v.(arm+"_HEIGHT")];
    delta=[v.(arm+"_SPAN"),s*v.(arm+"_LATERAL_DELTA"),v.(arm+"_HEIGHT_DELTA")];
    pivots=[midpoint-delta/2;midpoint+delta/2];
    seedRequire(all(s*pivots(:,2)>0) && all(s*pivots(:,2)<s*ball(2)), arm+":INBOARD_LATERALITY_REQUIRED");
    xyz(rows(j):rows(j)+1,:)=pivots;
end
xyz(7,:)=[C(1)+v.TIE_IN_X,s*v.TIE_IN_LATERAL,v.TIE_IN_HEIGHT];
dependencyRows=cell(10,1);
wheel=["WHEEL_EFFECTIVE_RADIUS";"NOMINAL_TOE";"NOMINAL_CAMBER"];
base=["WHEELBASE";trackId];
parameterNames=string(fieldnames(v));
for j=[1,2], dependencyRows{j}=[base;parameterNames(startsWith(parameterNames,"UCA_"))]; end
for j=[4,5], dependencyRows{j}=[base;parameterNames(startsWith(parameterNames,"LCA_"))]; end
for j=[3,6,8]
    prefix="UBJ"; if j==6, prefix="LBJ"; elseif j==8, prefix="TIE_OUT"; end
    dependencyRows{j}=[base;wheel;"UPRIGHT_CLOCKING";prefix+"_X";prefix+"_OUTBOARD";prefix+"_Z"];
end
dependencyRows{7}=[base;"TIE_IN_X";"TIE_IN_LATERAL";"TIE_IN_HEIGHT"];
dependencyRows{9}=[base;wheel]; dependencyRows{10}=base;
notes=strings(10,3);
for j=1:10, notes(j,:)= "DERIVED parametric seed; input IDs: "+strjoin(dependencyRows{j},","); end
geometry=fsd.model.createDoubleWishboneGeometry(corner,corner+"_"+fsd.model.requiredHardpointRoles(), ...
    xyz,'m',axis,struct('sourceKind',"DERIVED",'sourceNote',notes));
fsd.synthesis.validateNominalSeed(geometry);
frame=struct('cornerId',corner,'id',"UPRIGHT_NOMINAL",'origin_m',WC,'rotationMatrix',R, ...
    'referenceConvention',"VEHICLE_PARALLEL_SIDE_NORMALIZED_OFFSETS",'wheelAxis',geometry.wheel.wheelAxis, ...
    'wheelPlane',struct('point_m',WC,'unitNormal',geometry.wheel.wheelAxis));
derivations=struct('cornerId',corner,'reflectionOf',"",'pointIds',geometry.hardpoints.ids, ...
    'inputIds',{dependencyRows},'parameters',{parameters},'referenceParameters',{references});
end
