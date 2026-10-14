function valid = validateVehicleConcept(concept)
%VALIDATEVEHICLECONCEPT Structural validation accepts unknown optional data.
try
    expected=conceptCore(concept.definitionSI); projectRequire(isequaln(concept,expected),'Vehicle concept mismatch.');
catch cause
    throwAsCaller(addCause(MException('fsd:project:InvalidVehicleConcept','Inconsistent vehicle concept.'),cause));
end
valid=true;
end
