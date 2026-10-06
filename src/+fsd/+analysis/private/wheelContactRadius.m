function radius_m = wheelContactRadius(geometry)
%WHEELCONTACTRADIUS Validate the static datum and return ideal radius.

cornerId = string(geometry.cornerId);
staticCenter_m = point(geometry, cornerId + "_WHEEL_CENTER");
staticDatum_m = point(geometry, cornerId + "_CONTACT_PATCH");
radius_m = norm(staticDatum_m - staticCenter_m, 2);
staticIdeal = fsd.geometry.geometricWheelContact( ...
    staticCenter_m, double(geometry.wheel.wheelAxis), radius_m);
tolerances = fsd.model.numericTolerances();
tolerance_m = 10 * (tolerances.AbsTol_m + tolerances.RelTol * ...
    max([abs(staticCenter_m(:)); abs(staticDatum_m(:)); radius_m; 1]));
if string(staticIdeal.status) ~= "FINITE" || ...
        max(abs(staticIdeal.point_m - staticDatum_m)) > tolerance_m || ...
        abs(staticDatum_m(3)) > tolerance_m
    error("fsd:analysis:IncompatibleWheelContactDatum", ...
        "Static CONTACT_PATCH must be the lowest point of the ideal " + ...
        "wheel circle and lie on nominal road Z=0.");
end
end

function point_m = point(geometry, pointId)
point_m = double(geometry.hardpoints.xyz_m( ...
    geometry.hardpoints.ids == pointId, :));
end
