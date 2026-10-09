function [R, first, second] = globalRotation(theta, phi)
%GLOBALROTATION Exact finite Rx(phi)*Ry(theta) and its angular derivatives.
ct = cos(theta); st = sin(theta); cp = cos(phi); sp = sin(phi);
X = [1,0,0;0,cp,-sp;0,sp,cp]; Y = [ct,0,st;0,1,0;-st,0,ct];
Xp = [0,0,0;0,-sp,-cp;0,cp,-sp]; Yp = [-st,0,ct;0,0,0;-ct,0,-st];
Xpp = [0,0,0;0,-cp,sp;0,-sp,-cp]; Ypp = [-ct,0,-st;0,0,0;st,0,-ct];
R = X*Y; first = cat(3,X*Yp,Xp*Y);
second = cat(3,X*Ypp,Xp*Yp,Xpp*Y);
end
