function definition=packagingInputs(geometry,sourceRevision)
%PACKAGINGINPUTS Explicit ASSUMED software demonstration, NOT recommended FS data.
% No dimension is a production default. Caller explicitly requests this fixture.
% Initial software values:4mm radii,12mm obstacle offset,2mm margin,100mm box.
% Provenance does not repeat values that the user can subsequently edit.
fsd.model.validateDoubleWishboneGeometry(geometry);
corner=geometry.cornerId; point=fsd.model.getPoint(geometry,corner+"_UBJ");
origin=fsd.model.getPoint(geometry,corner+"_UCA_FWD_CHASSIS");
binding=struct('mode',"FIXED",'cornerId',"",'pointIds',strings(0,1));
d=struct('id',"DEMO_TUBE",'componentId',corner+"_UCA_FWD_TUBE",'componentType',"TUBE", ...
    'role',"OCCUPIED",'frame',geometry.referenceFrame,'shape',"CAPSULE",'dimensions',.004, ...
    'transform',eye(4),'binding',struct('mode',"SEGMENT",'cornerId',corner, ...
    'pointIds',[corner+"_UCA_FWD_CHASSIS";corner+"_UBJ"]), ...
    'source',"packagingInputs synthetic software fixture",'fidelity',"SIMPLIFIED_SOFTWARE_CASE", ...
    'sourceRevision',sourceRevision,'provenance',"ASSUMED software-only dimensions declared in this record; not vehicle advice");
tube=fsd.packaging.createVolume(d,'m');
d.id="DEMO_OBSTACLE"; d.componentId="DEMO_OBSTACLE"; d.componentType="OBSTACLE";
d.shape="SPHERE"; d.binding=binding; d.transform(1:3,4)=(point+[0 0 .012])';
obstacle=fsd.packaging.createVolume(d,'m');
d.id="DEMO_ALLOWED_REGION"; d.componentId="DEMO_ALLOWED_REGION"; d.componentType="OTHER";
d.shape="AABB"; d.role="FREE_REGION"; d.dimensions=[.1 .1 .1]; d.transform(1:3,4)=origin';
d.provenance="ASSUMED software-only box dimensions in this record; not a physical chassis region";
regionVolume=fsd.packaging.createVolume(d,'m');
pair=struct('id',"DEMO_PAIR",'first',"DEMO_TUBE",'second',"DEMO_OBSTACLE",'requiredClearance_m',.002,'exception',[]);
region=struct('id',"DEMO_REGION",'cornerId',corner,'pointId',corner+"_UCA_FWD_CHASSIS",'mode',"INSIDE", ...
    'volumeId',"DEMO_ALLOWED_REGION",'target_m',[],'tolerance_m',[],'clearance_m',0, ...
    'source',"packagingInputs centered-box test",'provenance',"ASSUMED software example, not a mounting recommendation");
definition=fsd.packaging.createDefinition(struct('id',"DEMO_PACKAGING",'volumes',{{tube;obstacle;regionVolume}}, ...
    'pairs',{{pair}},'regions',{{region}}));
end
