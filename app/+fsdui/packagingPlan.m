function plan=packagingPlan(parent,selection,index,cornerId,mode)
%PACKAGINGPLAN Copy a stored grid; no new requests or physical values inferred.
plan=struct('mode',string(mode),'requested_m',[]);
if plan.mode=="NOMINAL", return; end
assert(plan.mode=="BUMP" && ~isempty(parent),'fsd:ui:PackagingInput','Stored BUMP evidence required.');
if string(selection)=="REGISTRY"
    assert(parent.engine=="BUMP",'fsd:ui:PackagingInput','REGISTRY BUMP requires a native BUMP parent.');
    plan.requested_m=parent.nativePayload.sweep.requestedWheelTravel_m;
else
    history=parent.nativePayload.search.records;
    assert(isscalar(index) && index>=1 && fix(index)==index && index<=numel(history) && ~isempty(history{index}.candidate), ...
        'fsd:ui:PackagingInput','Stored candidate with native sources required.');
    sources=history{index}.candidate.definitionSI.sources; found=false;
    for j=1:numel(sources)
        s=sources{j};
        if s.type=="BUMP" && s.model.cornerId==cornerId
            plan.requested_m=s.sweep.requestedWheelTravel_m; found=true; break;
        end
    end
    assert(found,'fsd:ui:PackagingInput','Candidate has no stored BUMP for this corner.');
end
end
