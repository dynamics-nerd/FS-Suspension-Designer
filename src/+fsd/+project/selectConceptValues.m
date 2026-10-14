function selected = selectConceptValues(concept,selections)
%SELECTCONCEPTVALUES Explicit sampled scenario choices, never a robust interval claim.
fsd.project.validateVehicleConcept(concept); d=concept.definitionSI;
projectRequire(iscell(selections) && (isvector(selections) || isempty(selections)), 'Selection cell vector required.'); ids=strings(numel(selections),1);
for j=1:numel(selections)
    s=selections{j}; projectRequire(isstruct(s) && isscalar(s) && ...
        isequal(sort(string(fieldnames(s))),sort(["id";"value";"unit";"sourceNote"])), 'Explicit ID/value/unit/note required.');
    id=projectText(s.id); ids(j)=id; index=find(cellfun(@(p)p.id==id,d.parameters));
    projectRequire(isscalar(index),'Selection references an absent parameter.'); original=d.parameters{index};
    p=original.parameter.definitionSI; projectRequire(p.type~="RULE", ...
        'RULE_IS_NOT_A_PHYSICAL_INPUT: normative intervals cannot be sampled into physical assumptions.');
    projectRequire(~isempty(p.bounds) && p.type~="FIXED" && p.type~="TARGET", ...
        'Only explicit non-fixed physical intervals can be sampled.');
    value=fsd.model.convertDesignUnits(s.value,p.quantity,s.unit);
    projectRequire(isnumeric(value) && isscalar(value) && isfinite(value) && value>=p.bounds(1) && value<=p.bounds(2), ...
        'Selected value must lie in the declared SI interval.');
    p=rmfield(p,{'id','quantity','unit','scope','binding'}); p.value=value;
    if p.type=="DERIVED", p.type="RANGE"; end
    p.availability="ASSUMED"; p.sourceKind="ASSUMED"; p.sourceNote=projectText(s.sourceNote);
    p.metadata=original.parameter.metadata; p.metadata.intervalSelectionOrigin=original.identity;
    p.confirmation="DECLARED"; p.origin=original.origin;
    p.origin.limitations(end+1,1)="Explicit scenario sample, not a measurement or continuous robustness guarantee.";
    d.parameters{index}=conceptParameterCore(id,p,original.parameter.definitionSI.unit);
end
projectRequire(numel(unique(ids))==numel(ids),'Duplicate selection IDs.'); selected=conceptCore(d);
end
