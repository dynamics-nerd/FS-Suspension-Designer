function volume = createVolume(definition,inputUnit,circularMeasure)
%CREATEVOLUME Explicit simplified material/free-region geometry, not CAD.
% All physical fields are required; [] dimensions record missing data.
% Optional circularMeasure='DIAMETER' converts only dimension1 via r=D/2
% at this input boundary. Canonical storage is always radius (default RADIUS).
if nargin<3, circularMeasure="RADIUS"; end
d=definition;
required=["id","componentId","componentType","role","frame","shape","dimensions", ...
    "transform","binding","source","fidelity","sourceRevision","provenance"];
require(isstruct(d) && isscalar(d) && isequal(sort(string(fieldnames(d))),sort(required(:))), ...
    'Supply exactly the documented volume fields.');
for name=["id","componentId","componentType","role","shape","source","fidelity","provenance"]
    require((ischar(d.(name)) || isstring(d.(name))) && isscalar(string(d.(name))) && ...
        ~ismissing(string(d.(name))) && strlength(strtrim(string(d.(name))))>0,name+" requires explicit text.");
    d.(name)=string(d.(name));
end
require(~isempty(regexp(d.id,'^[A-Z][A-Z0-9_]*$','once')) && ...
    ~isempty(regexp(d.componentId,'^[A-Z][A-Z0-9_]*$','once')),'Canonical IDs required.');
require(ismember(d.shape,["SPHERE","CAPSULE","AABB","OBB","CYLINDER"]),'Unknown shape.');
require(ismember(d.role,["OCCUPIED","FREE_REGION"]),'Declare OCCUPIED or FREE_REGION.');
require(ismember(d.componentType,["TUBE","JOINT","UPRIGHT","TIRE_ENVELOPE","RIM_MATERIAL", ...
    "RIM_INTERIOR","OBSTACLE","ROCKER","DAMPER","OTHER"]),'Unknown component type.');
require(d.componentType~="RIM_INTERIOR" || d.role=="FREE_REGION",'Rim interior is free space, not occupied material.');
require(isstruct(d.frame) && isscalar(d.frame) && all(isfield(d.frame,{'id','originDescription','axisConvention'})) && ...
    string(d.frame.axisConvention)=="X_REAR_Y_RIGHT_Z_UP",'Supply the native parent frame and axis convention.');
require(isequal(sort(string(fieldnames(d.frame))),sort(["id";"originDescription";"axisConvention"])), 'Unknown parent-frame fields.');
for name=["id","originDescription","axisConvention"]
    value=d.frame.(name);
    require((ischar(value) || isstring(value)) && isscalar(string(value)) && ...
        ~ismissing(string(value)) && strlength(strtrim(string(value)))>0,'Frame fields require explicit scalar text.');
end
require(isstruct(d.binding) && isscalar(d.binding) && ...
    isequal(sort(string(fieldnames(d.binding))),sort(["mode";"cornerId";"pointIds"])), 'Invalid binding fields.');
b=d.binding; b.mode=string(b.mode); b.cornerId=string(b.cornerId); b.pointIds=string(b.pointIds(:));
require(isscalar(b.mode) && isscalar(b.cornerId) && ~any(ismissing([b.mode;b.cornerId;b.pointIds])) && ...
    ismember(b.mode,["FIXED","UPRIGHT","SEGMENT"]),'Invalid binding mode.');
if b.mode=="FIXED"
    require(strlength(b.cornerId)==0 && isempty(b.pointIds),'FIXED has no implicit corner or point binding.');
else
    require(ismember(b.cornerId,["FL","FR","RL","RR"]),'A mobile binding requires a corner ID.');
    if b.mode=="SEGMENT"
        require(d.shape=="CAPSULE" && numel(b.pointIds)==2 && b.pointIds(1)~=b.pointIds(2) && ...
            all(startsWith(b.pointIds,b.cornerId+"_")),'SEGMENT needs two explicit distinct corner point IDs and a capsule.');
    else
        require(isempty(b.pointIds),'UPRIGHT uses the verified pose, not an invented point frame.');
    end
end
d.binding=b;
require(isnumeric(d.dimensions) && isreal(d.dimensions) && (isvector(d.dimensions) || isempty(d.dimensions)) && ...
    all(isfinite(d.dimensions)),'Dimensions must be finite real lengths, or [] when missing.');
d.dimensions=fsd.model.convertLengthToMetres(double(d.dimensions(:)'),inputUnit);
measure=string(circularMeasure);
require(isscalar(measure) && ismember(measure,["RADIUS","DIAMETER"]),'Circular measure must be RADIUS or DIAMETER.');
if measure=="DIAMETER"
    require(ismember(d.shape,["SPHERE","CAPSULE","CYLINDER"]),'Diameter input applies only to circular primitives.');
    if ~isempty(d.dimensions), d.dimensions(1)=d.dimensions(1)/2; end
end
if ~isempty(d.dimensions)
    count=3; if d.shape=="SPHERE" || b.mode=="SEGMENT", count=1;
    elseif ismember(d.shape,["CAPSULE","CYLINDER"]), count=2; end
    require(numel(d.dimensions)==count,'Wrong dimension count for the declared shape/binding.');
    valid=all(d.dimensions>0);
    if d.shape=="CAPSULE" && b.mode~="SEGMENT", valid=d.dimensions(1)>0 && d.dimensions(2)>=0; end
    require(valid,'Radii/box sizes must be positive; only capsule centreline length may be zero.');
end
T=d.transform;
require(isnumeric(T) && isreal(T) && isequal(size(T),[4 4]) && all(isfinite(T),'all'),'Finite homogeneous transform required.');
tol=fsd.model.numericTolerances();
require(norm(T(4,:)-[0 0 0 1])<=tol.RelTol,'Transform must have homogeneous last row.');
fsd.geometry.transformPointsRigid([0 0 0],[0 0 0],[0 0 0],T(1:3,1:3));
T(1:3,4)=fsd.model.convertLengthToMetres(T(1:3,4),inputUnit); d.transform=double(T);
if d.shape=="AABB", require(isequal(T(1:3,1:3),eye(3)),'AABB axes must be parent-parallel; use OBB for rotations.'); end
if b.mode=="SEGMENT", require(isequal(T,eye(4)),'SEGMENT is defined by native endpoints, not an extra transform.'); end
require(isnumeric(d.sourceRevision) && isreal(d.sourceRevision) && isscalar(d.sourceRevision) && ...
    isfinite(d.sourceRevision) && d.sourceRevision>=1 && fix(d.sourceRevision)==d.sourceRevision,'Explicit positive source revision required.');
volume=struct('schemaVersion',"0.19.0",'kind',"PackagingVolume",'units',"m", ...
    'definitionSI',d,'identity',d);
end
function require(condition,message)
assert(condition,'fsd:packaging:InvalidVolume','%s',message);
end
