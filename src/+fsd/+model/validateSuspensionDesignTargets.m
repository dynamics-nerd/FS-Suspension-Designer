function valid = validateSuspensionDesignTargets(targets)
%VALIDATESUSPENSIONDESIGNTARGETS Reconstruct collection and identities.
designValidateRecord(targets,"SuspensionDesignTargets",@designTargetsCore); valid = true;
end
