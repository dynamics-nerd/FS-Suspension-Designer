function valid = validateDesignConstraint(constraint)
%VALIDATEDESIGNCONSTRAINT Reconstruct region, tolerance, scope and identity.
designValidateRecord(constraint,"DesignConstraint",@designConstraintCore); valid = true;
end
