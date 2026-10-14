function roles = actuationDesignPointRoles()
%ACTUATIONDESIGNPOINTROLES Nominal design points, not extra suspension hardpoints.
roles=["ACTUATION_ROD_SUSPENSION";"ACTUATION_ROD_ROCKER";"DAMPER_ROCKER"; ...
    "DAMPER_CHASSIS";"ROCKER_AXIS_POINT"];
end
