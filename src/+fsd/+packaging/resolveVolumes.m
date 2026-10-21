function [resolved,diagnostics,points]=resolveVolumes(definition,geometry,result)
%RESOLVEVOLUMES Consume an existing verified pose, never execute a solver.
% result=[] is the nominal state; failed native results keep unavailable volumes.
fsd.packaging.validateDefinition(definition); fsd.model.validateDoubleWishboneGeometry(geometry);
if nargin<3, result=[]; end
points=geometry.hardpoints; valid=true;
if ~isempty(result)
    if result.kind=="KinematicResult"
        fsd.kinematics.validateKinematicResult(result);
    elseif result.kind=="SteeringCornerResult"
        fsd.kinematics.validateSteeringCornerResult(result);
    else
        error('fsd:packaging:UnsupportedState','Only verified native corner states can be consumed.');
    end
    assert(isequaln(result.geometryIdentity,fsd.model.geometryIdentity(geometry)), ...
        'fsd:packaging:GeometryMismatch','Stored pose belongs to another geometry.');
    valid=result.converged;
    for j=1:numel(result.state.pointIds)
        k=points.ids==result.state.pointIds(j); points.xyz_m(k,:)=result.state.xyz_m(j,:);
    end
    if result.kind=="SteeringCornerResult"
        points.xyz_m(points.ids==geometry.cornerId+"_TIE_ROD_INBOARD",:)=result.tieRodInboardCurrent_m;
    end
end
volumes=definition.definitionSI.volumes; resolved=cell(size(volumes)); diagnostics=strings(size(volumes));
for j=1:numel(volumes)
    d=volumes{j}.definitionSI; binding=d.binding;
    if ~isequaln(d.frame,geometry.referenceFrame)
        diagnostics(j)="FRAME_MISMATCH"; continue;
    end
    if binding.mode~="FIXED" && binding.cornerId~=geometry.cornerId
        diagnostics(j)="CORNER_NOT_IN_SUPPLIED_STATE"; continue;
    end
    if binding.mode~="FIXED" && ~valid
        diagnostics(j)="SOURCE_NOT_CONVERGED"; continue;
    end
    if binding.mode=="UPRIGHT" && ~isempty(result)
        pose=result.uprightPose;
        centre=fsd.geometry.transformPointsRigid(d.transform(1:3,4)',pose.referencePointStatic_m, ...
            pose.translation_m,pose.rotationMatrix);
        d.transform=[pose.rotationMatrix*d.transform(1:3,1:3),centre';0 0 0 1];
        if d.shape=="AABB", d.shape="OBB"; end
    elseif binding.mode=="SEGMENT"
        indices=zeros(2,1);
        for k=1:2
            found=find(points.ids==binding.pointIds(k));
            if isscalar(found), indices(k)=found; end
        end
        if any(indices==0), diagnostics(j)="POINT_BINDING_NOT_AVAILABLE"; continue; end
        endpoints=points.xyz_m(indices,:); delta=diff(endpoints); length_m=norm(delta); R=eye(3);
        if length_m>0
            z=delta'/length_m; [~,index]=min(abs(z)); basis=zeros(3,1); basis(index)=1;
            x=cross(basis,z); x=x/norm(x); R=[x,cross(z,x),z];
        end
        d.transform=[R,mean(endpoints,1)';0 0 0 1];
        if ~isempty(d.dimensions), d.dimensions=[d.dimensions(1),length_m]; end
    end
    d.binding=struct('mode',"FIXED",'cornerId',"",'pointIds',strings(0,1));
    resolved{j}=fsd.packaging.createVolume(d,'m'); diagnostics(j)="RESOLVED";
end
end
