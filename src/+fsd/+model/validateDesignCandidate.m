function valid = validateDesignCandidate(candidate)
%VALIDATEDESIGNCANDIDATE Structural identity/model checks; no analysis dependency.
designValidateRecord(candidate,"DesignCandidate",@designCandidateCore); valid = true;
end
