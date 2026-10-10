function valid = validateDesignTarget(target)
%VALIDATEDESIGNTARGET Check catalog pairing, complete bands, scales and identity.
designValidateRecord(target,"DesignTarget",@designTargetCore); valid = true;
end
