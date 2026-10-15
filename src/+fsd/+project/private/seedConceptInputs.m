function inputs = seedConceptInputs(concept,definition)
%SEEDCONCEPTINPUTS Use the v0.16 selector, including pending confirmation/RULE.
fsd.project.validateVehicleConcept(concept); fsd.construction.validateParametricSeedDefinition(definition);
inputs=struct('parameters',{{}},'identities',{{}},'missing',strings(0,1),'diagnostics',strings(0,1), ...
    'architecture',"UNSELECTED");
axis="front"; if ismember(definition.definitionSI.cornerId,["RL","RR"]), axis="rear"; end
inputs.architecture=concept.definitionSI.architectures.(axis+"Suspension");
for id=fsd.construction.seedReferenceIds(definition)'
    [value,status,p]=conceptScalar(concept,id);
    if isempty(value)
        inputs.missing(end+1,1)="CONCEPT:"+id; inputs.diagnostics(end+1,1)=id+":"+status;
    else
        inputs.parameters{end+1,1}=p.parameter;
        inputs.identities{end+1,1}=p.parameter.identity;
    end
end
end
