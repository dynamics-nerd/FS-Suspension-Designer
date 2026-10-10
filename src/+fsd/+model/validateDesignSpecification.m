function valid = validateDesignSpecification(specification)
%VALIDATEDESIGNSPECIFICATION Reconstruct all nested definitions and physical identity.
designValidateRecord(specification,"DesignSpecification",@designSpecificationCore); valid = true;
end
