function [current,diagnostic] = seedBindingCurrent(project,binding)
%SEEDBINDINGCURRENT Relevant dimensions/recipe only; mass and presentation ignored.
current=false; diagnostic="STALE_PARAMETRIC_SEED:"+binding.scenarioId;
if binding.projectId~=project.id || binding.projectRevision>project.definition.revision, return; end
scenarios=project.definition.scenarios; idx=find(cellfun(@(s)s.definition.id==binding.scenarioId,scenarios));
if isempty(idx), return; end
d=scenarios{idx}.definition;
if ~ismember(d.engine,["PARAMETRIC_SEED","PARAMETRIC_BUMP"]) || ~isfield(d.inputs,'definition'), return; end
seed=binding.construction; definition=d.inputs.definition;
if ~isequaln(definition.identity,seed.definition.identity), return; end
inputs=seedConceptInputs(project.definition.concept,definition);
if ~isempty(inputs.missing) || ~ismember(inputs.architecture,["UNSELECTED","DOUBLE_WISHBONE"]), return; end
expected=cellfun(@(p)p.identity,inputs.parameters,'UniformOutput',false);
original=cellfun(@(p)p.identity,seed.referenceParameters,'UniformOutput',false);
% References are canonicalized by ID in construction records.
[~,order]=sort(cellfun(@(p)p.definitionSI.id,inputs.parameters)); expected=expected(order);
current=isequaln(expected,original); if current, diagnostic="MATCH"; end
end
