function metrics = staticMetrics(geometry)
%STATICMETRICS Compute only elementary static v0.1 dimensions.

fsd.model.validateDoubleWishboneGeometry(geometry);
prefix = geometry.cornerId + "_";
metrics = struct();
metrics.ucaInboardAxisLength_m = fsd.geometry.distanceBetweenPoints( ...
    geometry, prefix + "UCA_FWD_CHASSIS", prefix + "UCA_AFT_CHASSIS");
metrics.lcaInboardAxisLength_m = fsd.geometry.distanceBetweenPoints( ...
    geometry, prefix + "LCA_FWD_CHASSIS", prefix + "LCA_AFT_CHASSIS");
metrics.ubjLbjDistance_m = fsd.geometry.distanceBetweenPoints( ...
    geometry, prefix + "UBJ", prefix + "LBJ");
metrics.wheelCenterContactPatchDistance_m = ...
    fsd.geometry.distanceBetweenPoints(geometry, ...
    prefix + "WHEEL_CENTER", prefix + "CONTACT_PATCH");
end

