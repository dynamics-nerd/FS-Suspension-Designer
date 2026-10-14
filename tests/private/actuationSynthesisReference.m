function [compression,mr,curvature,rate,theta] = actuationSynthesisReference(actuation,z,k,preload)
%ACTUATIONSYNTHESISREFERENCE Independent circle-fixture implicit derivatives.
% Only the example's UPRIGHT pure-translation geometry (arm radius .3 m).
% No production solver, numerical derivative helper or assessment is called.
assert(actuation.suspensionAttachment.body=="UPRIGHT");
side=-1; if ismember(actuation.cornerId,["FR","RR"]), side=1; end
radius=.3; root=sqrt(radius^2-z^2);
s=actuation.suspensionAttachment.pointStatic_m+[0,-side*(radius-root),z];
sp=[0,-side*z/root,1]; spp=[0,-side*radius^2/root^3,0];
axis=actuation.rocker.axis; u=axis.direction_unit; origin=axis.point_m;
rod=actuation.rocker.actuationRodPoint.pointStatic_m;
centre=origin+dot(rod-origin,u)*u; radial=rod-centre; tangent=cross(u,radial);
lengthSquared=norm(rod-actuation.suspensionAttachment.pointStatic_m)^2;
w=centre-s; A=2*dot(w,radial); B=2*dot(w,tangent);
D=lengthSquared-dot(w,w)-dot(radial,radial);
angles=atan2(B,A)+[-1,1]*acos(D/hypot(A,B)); angles=atan2(sin(angles),cos(angles));
[~,index]=min(abs(angles)); theta=angles(index);
p=centre+radial*cos(theta)+tangent*sin(theta);
pt=-radial*sin(theta)+tangent*cos(theta); ptt=-radial*cos(theta)-tangent*sin(theta); e=p-s;
ft=2*dot(e,pt); ftt=2*(dot(pt,pt)+dot(e,ptt));
ftz=-2*dot(sp,pt); fzz=2*(dot(sp,sp)-dot(e,spp));
thetaPrime=2*dot(e,sp)/ft;
thetaSecond=-(ftt*thetaPrime^2+2*ftz*thetaPrime+fzz)/ft;
damper=actuation.rocker.damperPoint.pointStatic_m;
dc=origin+dot(damper-origin,u)*u; dr=damper-dc; dt=cross(u,dr);
d=dc+dr*cos(theta)+dt*sin(theta);
dtheta=-dr*sin(theta)+dt*cos(theta); dtt=-dr*cos(theta)-dt*sin(theta);
dp=dtheta*thetaPrime; dpp=dtt*thetaPrime^2+dtheta*thetaSecond;
v=d-actuation.damper.chassisPoint.point_m; length=norm(v);
compression=norm(damper-actuation.damper.chassisPoint.point_m)-length;
mr=-dot(v,dp)/length;
curvature=-((dot(dp,dp)+dot(v,dpp))/length-dot(v,dp)^2/length^3);
force=k*max(preload+compression,0);
rate=k*mr^2+force*curvature; % Engaged known cases only; not a production spring law.
end
