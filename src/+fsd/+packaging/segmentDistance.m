function [distance_m,p_m,q_m]=segmentDistance(a_m,b_m,c_m,d_m)
%SEGMENTDISTANCE Minimum of two closed finite segments, including point limits.
% Mathematical derivation/degenerate cases: docs/packaging-physical-feasibility.md.
points=[a_m;b_m;c_m;d_m];
assert(isnumeric(points) && isreal(points) && isequal(size(points),[4 3]) && all(isfinite(points),'all'), ...
    'fsd:packaging:InvalidPoint','Four finite 1-by-3 point rows required.');
u=b_m-a_m; v=d_m-c_m; w=a_m-c_m;
A=dot(u,u); C=dot(v,v);
parameters=[0,project(a_m,c_m,v,C);1,project(b_m,c_m,v,C); ...
    project(c_m,a_m,u,A),0;project(d_m,a_m,u,A),1];
% Cross-product form avoids cancellation for almost-parallel directions.
crossed=cross(u,v); stableDet=dot(crossed,crossed);
if stableDet>0
    s=dot(cross(v,w),crossed)/stableDet;
    t=dot(cross(u,w),crossed)/stableDet;
    if s>=0 && s<=1 && t>=0 && t<=1, parameters(end+1,:)=[s,t]; end
end
p=a_m+parameters(:,1).*u; q=c_m+parameters(:,2).*v;
[~,index]=min(sum((p-q).^2,2)); p_m=p(index,:); q_m=q(index,:);
distance_m=norm(p_m-q_m);
end
function t=project(p,a,v,lengthSquared)
if lengthSquared==0, t=0; else, t=min(1,max(0,dot(p-a,v)/lengthSquared)); end
end
