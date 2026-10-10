function mirrored = mirrorBumpDesignTarget(target, newId, newSourceId)
%MIRRORBUMPDESIGNTARGET Explicit lateral-reflection intent for side-signed bump angles.
% No generic rack/roll symmetry or assumption that the candidate is symmetric.
fsd.model.validateDesignTarget(target); d = target.definitionSI;
designRequire(d.sourceType == "BUMP" && d.scope.kind == "CORNER" && ...
    any(d.metricId == ["CAMBER","TOE","BUMP_STEER","CASTER","KPI"]) && ...
    isempty(d.requiredSourceIdentity),"Only unbound bump angle targets support this explicit mirror rule.");
ids = ["FL","FR","RL","RR"]; paired = ["FR","FL","RR","RL"];
d.id = designText(newId); d.sourceId = designText(newSourceId);
d.scope = fsd.model.designScope("CORNER",paired(ids == d.scope.id));
d.sourceNote = string(d.sourceNote)+"; explicit BUMP lateral reflection: same side-signed angle, unchanged wheel travel";
d.metadata = target.metadata;
mirrored = designTargetCore(d);
end
