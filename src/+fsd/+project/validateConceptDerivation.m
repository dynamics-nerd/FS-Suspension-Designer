function valid = validateConceptDerivation(derivation,concept)
%VALIDATECONCEPTDERIVATION Reconstruct native algebra, never kinematic solves.
try
    expected=conceptDerivationCore(derivation.concept,derivation.options);
    if ~isempty(derivation.loads), fsd.analysis.validateStaticVehicleLoads(derivation.loads,derivation.vehicle,derivation.loadCase); end
    projectRequire(isequaln(workflowComparable(derivation),workflowComparable(expected)), ...
        'Derived values or dependencies changed: '+strjoin([expected.missing;expected.diagnostics],'; '));
    if nargin>1, projectRequire(isequaln(concept.identity,derivation.conceptIdentity),'Derivation belongs to another concept revision.'); end
catch cause
    throwAsCaller(addCause(MException('fsd:project:InvalidConceptDerivation','Inconsistent or obsolete concept derivation.'),cause));
end
valid=true;
end
