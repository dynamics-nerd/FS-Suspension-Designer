function definition = replaceSeedDecision(definition,id,value,role)
%REPLACESEEDDECISION Test mutation through public factories, not payload patching.
if nargin<4, role="ASSUMED"; end
d=definition.definitionSI; ps=d.parameters; i=find(cellfun(@(p)p.definitionSI.id==string(id),ps));
p=ps{i}.definitionSI; input=rmfield(p,{'id','quantity','scope','binding','unit'});
input.metadata=ps{i}.metadata; input.type=string(role); input.value=value;
if isempty(value), input.availability="NOT_PROVIDED"; input.sourceKind="UNSPECIFIED";
else, input.availability="ASSUMED"; input.sourceKind="ASSUMED"; end
input.sourceNote="Explicit test-only decision change";
if string(role)=="KNOWN" || string(role)=="FIXED", input.availability="KNOWN"; input.sourceKind="KNOWN"; end
if string(role)=="DERIVED", input.availability="DERIVED"; input.sourceKind="DERIVED"; input.derivationReference="DECLARED_TEST_DERIVATION"; end
if string(role)=="RANGE" || string(role)=="FREE", input.bounds=[.1,.5]; end
if string(role)=="RULE"
    input.ruleReference=struct('organizer',"TEST",'version',"TEST",'ruleId',"FICTITIOUS", ...
        'quantity',p.quantity,'source',"TEST_ONLY",'status',"VERIFIED",'applicability',"SOFTWARE_TEST");
end
d.parameters{i}=fsd.construction.createSeedParameter(id,p.scope.cornerId,input,p.unit);
definition=fsd.construction.createParametricSeedDefinition(d);
end
