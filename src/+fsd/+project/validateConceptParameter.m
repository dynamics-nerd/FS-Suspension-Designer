function valid = validateConceptParameter(record)
%VALIDATECONCEPTPARAMETER Canonical native/wrapper reconstruction, no physics.
try
    fsd.model.validateDesignParameter(record.parameter); d=record.parameter.definitionSI;
    d=rmfield(d,{'id','quantity','unit','scope','binding'}); d.metadata=record.parameter.metadata;
    d.confirmation=record.confirmation; d.origin=record.origin; d.state=record.state; d.diagnostics=record.diagnostics;
    expected=conceptParameterCore(record.id,d,record.parameter.definitionSI.unit);
    projectRequire(isequaln(record,expected),'Concept parameter contradicts its definition.');
catch cause
    throwAsCaller(addCause(MException('fsd:project:InvalidConceptParameter','Inconsistent concept parameter.'),cause));
end
valid=true;
end
