function [value,status,parameter] = conceptScalar(concept,id)
%CONCEPTSCALAR Physical eligibility precedes availability/provenance/confirmation.
index=find(cellfun(@(p)p.id==id,concept.definitionSI.parameters));
value=[]; status="UNKNOWN"; parameter=[];
if isempty(index), return; end
parameter=concept.definitionSI.parameters{index}; status=parameter.state;
if parameter.parameter.definitionSI.type=="TARGET", status="TARGET_IS_NOT_A_FACT"; return; end
if parameter.parameter.definitionSI.type=="RULE", status="RULE_IS_NOT_A_PHYSICAL_INPUT"; return; end
if status=="AVAILABLE", value=parameter.parameter.definitionSI.value;
elseif status=="AVAILABLE_RANGE", status="INTERVAL_REQUIRES_EXPLICIT_NOMINAL"; end
end
