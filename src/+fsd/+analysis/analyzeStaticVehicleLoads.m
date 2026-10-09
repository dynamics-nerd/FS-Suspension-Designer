function result = analyzeStaticVehicleLoads(vehicle, loadCase)
%ANALYZESTATICVEHICLELOADS Vertical force/moment balance, not chassis equilibrium.
fsd.model.validateVehicleLoadCase(loadCase,vehicle);
result = staticLoadCore(vehicle,loadCase);
end
