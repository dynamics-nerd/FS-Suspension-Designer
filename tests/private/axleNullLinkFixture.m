function [space,u] = axleNullLinkFixture(arm,side,pickup,allInvalid)
%AXLENULLLINKFIXTURE Reuse the F04 native reproducer on an explicitly supplied pair.
if nargin<4, allInvalid=false; end
mode="ORIGINAL"; if allInvalid, mode="ALL_INVALID"; end
[corner,bad]=zeroLengthLinkFixture(arm,mode,pickup);
left=corner.seed; right=fsd.geometry.reflectDoubleWishboneGeometry(left); seeds={left;right};
d=corner.specification.definitionSI; params=cell(2,1);
for j=1:2
    p=d.parameters{1}.definitionSI; p.id=seeds{j}.cornerId+"_NULL_X";
    p.scope=fsd.model.designScope('HARDPOINT',seeds{j}.cornerId+"_"+extractAfter(p.scope.id,3),seeds{j}.cornerId);
    params{j}=fsd.model.createDesignParameter(p,'m');
end
d.parameters=params; d.constraints={}; targets=d.targets.definitionSI.targets;
for k=1:numel(targets)
    t=targets{k}.definitionSI; t.id="CONTROL_"+k; targets{k}=fsd.model.createDesignTarget(t,'rad','m');
end
d.targets=fsd.model.createSuspensionDesignTargets(targets);
space=fsd.synthesis.createAxleDesignSpace(left,right,fsd.model.createDesignSpecification(d), ...
    struct('leftBump',struct('travel_m',0),'rightBump',struct('travel_m',0)));
u=fsd.synthesis.normalizeAxleVariables(space,space.initial_m); u(side)=bad;
end
