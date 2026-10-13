function [axle,changes] = axleBuildCore(space,x_m)
%AXLEBUILDCORE Apply physical symmetry before calling the historical builders.
coordinateCore(space,x_m,"NORMALIZE");
x_m=x_m(:); physical=space.multiplier.*x_m(space.independentIndex);
n=numel(space.cornerSpaces{1}.variables);
[left,lchanges]=buildCore(space.cornerSpaces{1},physical(1:n));
[right,rchanges]=buildCore(space.cornerSpaces{2},physical(n+1:end));
axle=fsd.model.createAxleGeometry(left,right); changes=[lchanges;rchanges];
end
