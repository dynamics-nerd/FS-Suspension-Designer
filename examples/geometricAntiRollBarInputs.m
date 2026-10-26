function definition=geometricAntiRollBarInputs(project,axleId,body)
%GEOMETRICANTIROLLBARINPUTS Explicit synthetic draft from existing native resources.
% No geometry is created and no physical parameter is recommended for FS use.
if nargin<2, axleId="FRONT"; end
if nargin<3, body="ROCKER"; end
ids=["FL","FR"]; if string(axleId)=="REAR", ids=["RL","RR"]; end
points=zeros(2,3); resources=project.definition.resources;
for k=1:2
    i=cellfun(@(g)g.cornerId==ids(k),resources.geometries); assert(nnz(i)==1,'fsd:example:MissingGeometry','Two explicit native corner geometries required.');
    g=resources.geometries{i};
    if string(body)=="ROCKER"
        i=cellfun(@(a)a.cornerId==ids(k),resources.actuations); assert(nnz(i)==1,'fsd:example:MissingActuation','Native rocker resources required.');
        a=resources.actuations{i}; points(k,:)=a.rocker.actuationRodPoint.pointStatic_m;
    elseif string(body)=="UCA", points(k,:)=fsd.model.getPoint(g,ids(k)+"_UBJ");
    elseif string(body)=="LCA", points(k,:)=fsd.model.getPoint(g,ids(k)+"_LBJ");
    else, points(k,:)=fsd.model.getPoint(g,ids(k)+"_WHEEL_CENTER");
    end
end
direction=diff(points); direction=direction/norm(direction);
radial=cross(direction,[0,0,1]); radial=.1*radial/norm(radial);
arms=points+[0,0,.2]; centers=arms-radial;
definition=antiRollBarInputs('COAXIAL_TORSION',axleId); p=definition.parameters;
p.axisPoint_m=centers(1,:); p.axisDirection_unit=direction;
p.supports_m=[centers(1,:)+.1*direction;centers(2,:)-.1*direction];
p.armPoints_m=arms; p.driverPoints_m=points; p.linkLengths_m=[.2;.2];
p.wheelTravelDomain_m=[-.02,.02;-.02,.02];
definition.parameters=p; definition.drivers=repmat(string(body),2,1);
definition.referenceFrame=g.referenceFrame;
definition.note="Explicit synthetic draft using the selected native resources; engineering dimensions are assumptions, not FS recommendations.";
end
