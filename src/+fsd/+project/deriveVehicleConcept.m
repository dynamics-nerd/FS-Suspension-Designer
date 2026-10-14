function derivation = deriveVehicleConcept(concept,options)
%DERIVEVEHICLECONCEPT Explicit bookkeeping and native v0.9 load calculations.
if nargin<2, options=struct(); end
derivation=conceptDerivationCore(concept,options);
end
