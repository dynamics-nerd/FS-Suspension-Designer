function velocity = mechanicalVelocityInput(value, count, unit)
%MECHANICALVELOCITYINPUT Scalar broadcast or one finite velocity per sample.
validateattributes(value,{'numeric'},{'real','finite','vector','nonempty'});
if ~isscalar(value) && numel(value) ~= count
    error("fsd:analysis:InvalidSpringDamperAnalysis","Velocity count mismatch.");
end
velocity = fsd.model.convertMechanicalUnits(value(:),"velocity",unit,"m/s");
if isscalar(velocity), velocity = repmat(velocity,count,1); end
end
