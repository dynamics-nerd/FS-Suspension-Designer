function [rate, mr, curvature] = rockerWheelRateReference(z, stiffness, preload)
%ROCKERWHEELRATEREFERENCE Independent analytic derivatives of circle/sphere fixture.
% No production solver/derivative helper is called. Rod closure f(theta,z)=0:
% theta'=-fz/ftheta; theta''=-(ftt*theta'^2+2*ftz*theta'+fzz)/ftheta.
radius = 0.3; r = [0,0.1,0]; t = [0,0,0.1];
s = [0,0.15+radius-sqrt(radius^2-z^2),0.1+z];
sp = [0,z/sqrt(radius^2-z^2),1];
spp = [0,radius^2/(radius^2-z^2)^(3/2),0];
rodSquared = 0.05^2+0.1^2;
A = -2*dot(s,r); B = -2*dot(s,t);
D = rodSquared-dot(s,s)-dot(r,r);
angles = atan2(B,A)+[1,-1]*acos(D/hypot(A,B));
[~,index] = min(abs(angles)); theta = angles(index);
p = r*cos(theta)+t*sin(theta);
pt = -r*sin(theta)+t*cos(theta); ptt = -p; e = p-s;
ft = 2*dot(e,pt); ftt = 2*(dot(pt,pt)+dot(e,ptt));
ftz = -2*dot(sp,pt); fzz = 2*(dot(sp,sp)-dot(e,spp));
thetaPrime = 2*dot(e,sp)/ft;
thetaSecond = -(ftt*thetaPrime^2+2*ftz*thetaPrime+fzz)/ft;
d = t*cos(theta)-r*sin(theta);
dt = -t*sin(theta)-r*cos(theta); dtt = -d;
chassis = [0.12,-0.08,0.16]; v = d-chassis; length = norm(v);
dp = dt*thetaPrime; dpp = dtt*thetaPrime^2+dt*thetaSecond;
mr = -dot(v,dp)/length;
curvature = -((dot(dp,dp)+dot(v,dpp))/length-dot(v,dp)^2/length^3);
compression = norm(t-chassis)-length;
force = stiffness*max(preload+compression,0);
rate = stiffness*mr^2+force*curvature;
end
