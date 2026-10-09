function identity = vehicleIdentity(vehicle)
%VEHICLEIDENTITY Physical and operating inputs, excluding presentation metadata.
fsd.model.validateVehicleParameters(vehicle);
identity = vehicle.identity;
end
