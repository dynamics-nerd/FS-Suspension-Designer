function point=antiRollBarDriverPoint(bar,side,source)
%ANTIROLLBARDRIVERPOINT Consume a verified existing pose; no suspension solve.
fsd.model.validateAntiRollBar(bar);
assert(ismember(side,[1,2])&&isstruct(source)&&isscalar(source)&&all(isfield(source,{'geometry','state'})), ...
    'fsd:kinematics:InvalidAntiRollBar','Corner geometry and native state required.');
g=source.geometry; fsd.model.validateDoubleWishboneGeometry(g); state=source.state;
assert(isequaln(g.referenceFrame,bar.definition.referenceFrame),'fsd:kinematics:InvalidAntiRollBar','Driver source uses another complete coordinate frame.');
ids=["FL","FR"]; if bar.definition.axleId=="REAR", ids=["RL","RR"]; end
assert(g.cornerId==ids(side),'fsd:kinematics:InvalidAntiRollBar','ARB/source side mismatch.');
body=bar.definition.drivers(side); initial=bar.definition.parameters.driverPoints_m(side,:);
if state.kind=="ActuationResult"
    assert(isfield(source,'actuation'),'fsd:kinematics:InvalidAntiRollBar','Actuation geometry required.');
    fsd.kinematics.validateActuationResult(state,source.actuation);
    native=state.sourceResult;
else, native=state; validateActuationSource(native);
end
assert(isequaln(native.geometryIdentity,fsd.model.geometryIdentity(g))&&native.converged, ...
    'fsd:kinematics:InvalidAntiRollBar','Driver source must be converged and belong to this geometry.');
if body=="ROCKER"
    assert(state.kind=="ActuationResult"&&state.converged&&~state.isIllConditioned, ...
        'fsd:kinematics:InvalidAntiRollBar','Verified non-singular rocker state required.');
    a=source.actuation;
    point=fsd.geometry.rotatePointsAboutAxis(initial,a.rocker.axis.point_m,a.rocker.axis.direction_unit,state.rockerAngle_rad);
else
    % Adapter to the existing material-point transform, not an actuation model.
    binding=struct('suspensionAttachment',struct('body',body,'pointStatic_m',initial), ...
        'cornerGeometryIdentity',fsd.model.geometryIdentity(g));
    point=actuationAttachmentCurrent(binding,native);
end
end
