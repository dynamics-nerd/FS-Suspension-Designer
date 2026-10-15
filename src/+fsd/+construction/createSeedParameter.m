function parameter = createSeedParameter(id,cornerId,input,unit)
%CREATESEEDPARAMETER Use the native role/unit/provenance contract for one decision.
c=fsd.construction.seedParameterCatalog(); k=find(string({c.id})==string(id));
seedRequire(isscalar(k),'Unknown construction parameter ID.');
seedRequire(isstruct(input) && isscalar(input) && ...
    ~any(isfield(input,{'id','quantity','scope','binding','unit'})), 'Catalog controls ID/quantity/scope/binding/unit.');
d=input; d.id=string(id); d.quantity=c(k).quantity;
d.scope=fsd.model.designScope('COMPONENT','PARAMETRIC_SEED',cornerId); d.binding="NONE";
parameter=fsd.model.createDesignParameter(d,unit);
end
