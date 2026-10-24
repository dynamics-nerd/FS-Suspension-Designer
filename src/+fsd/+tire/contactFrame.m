function result=contactFrame(heading,wheelAxis,cornerId,normal)
%CONTACTFRAME Proper contact rotation and signed lean; no side reflection frame.
if nargin<4, normal=[0,0,1]; end
assert(isnumeric(heading)&&isnumeric(wheelAxis)&&isnumeric(normal)&&isequal(size(heading),[1,3])&& ...
    isequal(size(wheelAxis),[1,3])&&isequal(size(normal),[1,3])&&all(isfinite([heading,wheelAxis,normal])), ...
    'fsd:tire:InvalidFrame','Finite 1-by-3 vectors required.');
assert(ismember(string(cornerId),["FL","FR","RL","RR"]),'fsd:tire:InvalidFrame','Canonical corner required.');
assert(norm(normal)>0&&norm(wheelAxis)>0,'fsd:tire:InvalidFrame','Nonzero normal and wheel axis required.');
z=normal/norm(normal); axis=wheelAxis/norm(wheelAxis);
% Rolling direction is the actual wheel-plane/road-plane intersection.
x=cross(axis,z);
assert(norm(x)>0&&dot(x,heading)~=0,'fsd:tire:InvalidFrame','Heading must orient the wheel/road intersection.');
x=x/norm(x); if dot(x,heading)<0, x=-x; end
y=cross(z,x);
top=z-dot(z,axis)*axis;
assert(norm(top)>0,'fsd:tire:InvalidFrame','Wheel plane has no upward direction.');
top=top/norm(top);
result=struct('rotationContactToGlobal',[x(:),y(:),z(:)], ...
    'gamma_rad',atan2(dot(top,y),dot(top,z)),'cornerId',string(cornerId), ...
    'frame',"CONTACT_FORWARD_LEFT_UP");
end
