function context=validationContext(cache)
%VALIDATIONCONTEXT Operation-local exact proofs, never global or caller-supplied.
% Handles capture only this Map, never their own context struct. Cached keys
% and outputs are plain values, so no cache/closure reference cycle is retained.
if nargin<1, cache=containers.Map('KeyType','char','ValueType','any'); end
context=struct('project',@(v)checkProject(v,cache), ...
    'result',@(v)validateResultCore(v,validationContext(cache)), ...
    'source',@(v)validateSourceCore(v,validationContext(cache)), ...
    'reference',@(v)referenceProof(v,cache), ...
    'prepare',@(p,s)prepare(p,s,cache),'resources',@(v)memo(cache,'resources',v,@()plainResources(v)), ...
    'concept',@(v)memo(cache,'concept',v,@()plainProof(v,@fsd.project.validateVehicleConcept)), ...
    'scenario',@(v)plainProof(v,@fsd.project.validateEngineeringScenario), ...
    'derivation',@(v)memo(cache,'derivation',v,@()plainProof(v,@fsd.project.validateConceptDerivation)), ...
    'payload',@(p,v)validateScenarioPayload(p,v,validationContext(cache)), ...
    'nativeSynthesis',@(v,e)memo(cache,'nativeSynthesis',struct('engine',e,'payload',v),@()nativeSynthesis(v,e)));
end
function valid=plainProof(value,validator)
valid=validator(value); plainProjectData(value);
end
function resources=plainResources(input)
resources=resourceCore(input); plainProjectData(resources);
end
function valid=checkProject(project,cache)
projectRequire(isequaln(project,projectCore(project.definition,validationContext(cache))), ...
    'Project identity or definition mismatch.'); valid=true;
end
function valid=referenceProof(value,cache)
dependency=isstruct(value) && isscalar(value) && isfield(value,'kind') && ...
    (isstring(value.kind) || ischar(value.kind)) && isscalar(string(value.kind)) && ...
    string(value.kind)=="PackagingSourceReference";
context=validationContext(cache);
if dependency, valid=context.source(value); else, valid=context.result(value); end
end
function value=prepare(project,scenario,cache)
% Neither ledger is consumed by preparation; retain every other field exactly.
configuration=project; configuration.definition.results=cell(0,1);
configuration.definition.derivations=cell(0,1);
value=prepareScenarioCore(configuration,scenario,validationContext(cache));
end
function valid=nativeSynthesis(payload,engine)
switch engine
    case "CORNER_SYNTHESIS", fsd.synthesis.validateSynthesisResult(payload);
    case "AXLE_SYNTHESIS", fsd.synthesis.validateAxleSynthesisResult(payload);
    case "STEERING_SYNTHESIS", fsd.synthesis.validateSteeringSynthesisResult(payload);
    case "ACTUATION_SYNTHESIS", fsd.synthesis.validateActuationSynthesisResult(payload);
    otherwise, projectRequire(false,'Unsupported native synthesis validation.');
end
valid=true;
end
function value=memo(cache,group,key,compute)
bucket=group;
if isstruct(key) && isscalar(key)
    for field={'kind','id'}
        if isfield(key,field{1})
            hint=key.(field{1});
            if isstring(hint) && isscalar(hint) && ~ismissing(hint), bucket=[bucket,'|',char(hint)]; end %#ok<AGROW>
        end
    end
end
entries={}; if isKey(cache,bucket), entries=cache(bucket); end
for j=1:numel(entries)
    % IDs/revisions are hints, not proofs: compare all data, types and bits.
    if samePlainValue(entries{j}.key,key), value=entries{j}.value; return; end
end
value=compute(); % A failure never creates a proof.
if isKey(cache,bucket), entries=cache(bucket); end
entries{end+1}=struct('key',{key},'value',{value}); cache(bucket)=entries;
stored=cache(bucket); value=stored{end}.value;
end
