function [space,badU,jointRow] = zeroLengthLinkFixture(arm,mode,pickup)
%ZEROLENGTHLINKFIXTURE Native F04 reproducer; adversarial test-only coordinates.
if nargin<2, mode="ORIGINAL"; end
if nargin<3, pickup="FWD"; end
s=synthesisFixture(1); seed=s.seed;
rows=[1,2]; jointRow=3;
if arm=="LCA", rows=[4,5]; jointRow=6; end
row=rows(1); other=rows(2);
if pickup=="AFT", row=rows(2); other=rows(1); end
seed.hardpoints.xyz_m(row,2:3)=seed.hardpoints.xyz_m(jointRow,2:3);
seed.hardpoints.sourceNote(row,:)="F04 adversarial link-null fixture, not vehicle design";
a=seed.hardpoints.xyz_m(row,1); b=seed.hardpoints.xyz_m(jointRow,1);
if mode=="ALL_INVALID"
    % Native model admits collinear arm; builder rejects it. Other pickup is
    % outside the variable interval; endpoints never coincide with each other.
    seed.hardpoints.xyz_m(other,:)=[2*a-b,seed.hardpoints.xyz_m(jointRow,2:3)];
    seed.hardpoints.sourceNote(other,:)="F04 collinear start, not vehicle design";
end
d=s.specification.definitionSI; p=d.parameters{1}.definitionSI;
p.scope=fsd.model.designScope('HARDPOINT',seed.hardpoints.ids(row),'FL');
p.value=a; p.bounds=sort([a,b]); p.sourceNote="F04 test-only interval ending at ball joint";
d.parameters={fsd.model.createDesignParameter(p,'m')}; d.compositeScore=false;
space=fsd.synthesis.createDesignSpace(seed,fsd.model.createDesignSpecification(d),struct('travel_m',0));
badU=double(b==p.bounds(2));
end
