function response=workerResponse(response,request)
%WORKERRESPONSE Return only new records; never rewrite or transport old history.
if ~isfield(request,'ledgerPolicy'), return; end
response.ledgerPolicy=request.ledgerPolicy;
if request.ledgerPolicy=="UNCHANGED"
    assert(isequaln(response.project,request.project),'fsd:ui:HistoryMutation','Read-only operation changed the project.');
    response.project=[]; return;
end
if request.ledgerPolicy=="APPEND"
    previous=request.project.definition.results; records=response.project.definition.results;
    keep=true(numel(records),1);
    for j=1:numel(previous)
        match=cellfun(@(r)string(r.id)==string(previous{j}.id),records);
        assert(nnz(match)==1 && isequaln(records{match},previous{j}), ...
            'fsd:ui:HistoryMutation','Worker must preserve every original dependency record.');
        keep(match)=false;
    end
    response.project.definition.results=reshape(records(keep),[],1);
end
end
