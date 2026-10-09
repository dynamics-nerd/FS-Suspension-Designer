function vehicleRequire(condition, message)
%VEHICLEREQUIRE Common v0.9 contract failure.
if ~condition, error("fsd:model:InvalidVehicleParameters","%s",message); end
end
