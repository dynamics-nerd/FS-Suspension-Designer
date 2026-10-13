function space = synthesisFailureFixture(mode)
%SYNTHESISFAILUREFIXTURE Adversarial physical inputs, not recommended FS geometry.
if nargin<1, mode="ANALYSIS"; end
s=synthesisFixture(); d=s.specification.definitionSI; xyz=s.seed.hardpoints.xyz_m;
if mode=="ANALYSIS"
    xyz(3,:)=xyz(6,:)+[0,.1,0];
elseif mode=="BUILDER"
    xyz(1,:)=(xyz(2,:)+xyz(3,:))/2; % collinear UCA seed; native factory allows it
else
    error('fsd:test:UnknownFixture','Unknown audit fixture.');
end
g=fsd.model.createDoubleWishboneGeometry('FL',s.seed.hardpoints.ids,xyz,'m',[0,-1,0], ...
    struct('sourceKind',"ASSUMED",'sourceNote',"Adversarial audit fixture"));
for i=1:numel(d.parameters)
    p=d.parameters{i}.definitionSI; p.value=xyz(i,3); p.bounds=p.value+[-.01,.01];
    d.parameters{i}=fsd.model.createDesignParameter(p,'m');
end
t=d.targets.definitionSI.targets{1}.definitionSI;
t.type="POINT_TARGET"; t.x=0; t.value=0; t.tolerance=1; t.weight=[];
d.compositeScore=false; d.constraints={};
d.targets=fsd.model.createSuspensionDesignTargets({fsd.model.createDesignTarget(t,'rad','m')});
space=fsd.synthesis.createDesignSpace(g,fsd.model.createDesignSpecification(d),struct('travel_m',0));
end
