function point = getActuationDesignPoint(actuation,id)
%GETACTUATIONDESIGNPOINT Global nominal XYZ; axis point is not a bearing mount.
fsd.model.validateActuationGeometry(actuation);
ids=actuation.cornerId+"_"+fsd.model.actuationDesignPointRoles();
if ~((isstring(id) && isscalar(id) && ~ismissing(id)) || (ischar(id) && isrow(id)))
    error('fsd:model:UnknownActuationDesignPoint','A canonical point ID is required.');
end
j=find(ids==string(id));
if ~isscalar(j), error('fsd:model:UnknownActuationDesignPoint','Unknown actuation point ID.'); end
points=[actuation.suspensionAttachment.pointStatic_m;actuation.rocker.actuationRodPoint.pointStatic_m; ...
    actuation.rocker.damperPoint.pointStatic_m;actuation.damper.chassisPoint.point_m;actuation.rocker.axis.point_m];
point=points(j,:);
end
