function plan = actuationPlan(travel,velocity,mechanical)
%ACTUATIONPLAN Explicit mm and mm/s presentation boundary; no default velocity.
z=fsdui.numberList(travel);
assert(~isempty(z),'fsd:ui:ActuationInput','Declare the wheel travel samples in mm.');
plan=struct('travel_m',fsd.model.convertLengthToMetres(z,'mm'));
if mechanical
    v=fsdui.numberList(velocity);
    assert(isscalar(v) || numel(v)==numel(z),'fsd:ui:ActuationInput', ...
        'Declare velocity in mm/s: one scalar or one value per sample. Zero is prescribed rest.');
    plan.wheelVelocity_m_per_s=fsd.model.convertMechanicalUnits(v,'velocity','mm/s','m/s');
end
end
