function result=antiRollBarClosure(p,side,driver,reference,expectedBranch)
%ANTIROLLBARCLOSURE Circle/sphere geometry on a shared oriented shaft axis.
% P is a canonical parameter struct; this arithmetic kernel does no model solve.
if nargin<5, expectedBranch=0; end
axis=p.axisDirection_unit; pivot=p.axisPoint_m; initial=p.armPoints_m(side,:);
offset=initial-pivot; center=pivot+dot(offset,axis)*axis; radial=initial-center;
tangent=cross(axis,radial); w=center-driver; length_m=p.linkLengths_m(side);
A=2*dot(w,radial); B=2*dot(w,tangent); D=length_m^2-dot(w,w)-dot(radial,radial);
scale=max([abs(A),abs(B),abs(D),length_m^2,dot(w,w),dot(radial,radial),1]);
c=fsd.geometry.circleSphereRotation(A,B,D,scale,reference);
if any(~isfinite([A,B,D,scale,reference]))
    c.constraintCase="NUMERICALLY_UNRESOLVED"; c.isIllConditioned=true; c.conditioning=NaN;
end
result=struct('available',false,'status',c.constraintCase,'rotation_rad',NaN,'angle_rad',NaN, ...
    'armPoint_m',nan(1,3),'driverPoint_m',driver,'closureResidual_m',NaN, ...
    'branchSign',0,'conditioning',c.conditioning,'closure',c, ...
    'armTangent_m',nan(1,3),'armSecond_m',nan(1,3),'closureFirst_m2',NaN);
if ~ismember(c.constraintCase,["TWO_SOLUTIONS","TANGENT"]), return; end
beta=c.selectedAngle_rad; point=center+cos(beta)*radial+sin(beta)*tangent;
first=cross(axis,point-center); second=cross(axis,first); v=point-driver;
derivative=2*dot(v,first); branch=sign(derivative);
result.rotation_rad=beta; result.angle_rad=p.installationAngles_rad(side)+beta;
result.armPoint_m=point; result.armTangent_m=first; result.armSecond_m=second;
result.closureFirst_m2=derivative; result.closureResidual_m=norm(v)-length_m;
result.branchSign=branch;
if any(~isfinite([beta,result.angle_rad,point,first,second,derivative,result.closureResidual_m]))
    result.status="NUMERICALLY_UNRESOLVED"; return;
end
tol=fsd.model.numericTolerances(); budget=tol.AbsTol_m+tol.RelTol*max([abs(point),abs(driver),length_m,1]);
if abs(result.closureResidual_m)>10*budget, result.status="CLOSURE_POSTCHECK_FAILED";
elseif c.isIllConditioned, result.status="SINGULAR_OR_ILL_CONDITIONED";
elseif expectedBranch~=0&&branch~=expectedBranch, result.status="BRANCH_MISMATCH";
elseif result.angle_rad<p.armAngleDomain_rad(side,1)||result.angle_rad>p.armAngleDomain_rad(side,2)
    result.status="ARM_ANGLE_LIMIT";
else, result.status="AVAILABLE"; result.available=true;
end
end
