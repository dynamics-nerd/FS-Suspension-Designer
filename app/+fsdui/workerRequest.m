function request=workerRequest(request)
%WORKERREQUEST Keep the immutable full ledger at its owning UI session.
% These actions replace the project or need its complete history explicitly.
if ismember(request.action,["NEW","DEMO","LOAD"])
    request.project=[]; request.ledgerPolicy="REPLACE"; return;
end
if ismember(request.action,["SAVE","VALIDATE","COMPATIBILITY"])
    request.ledgerPolicy="UNCHANGED"; return;
end
request.ledgerPolicy="APPEND";
p=request.project; records=p.definition.results; needed="";
if ismember(request.action,["ADOPT","ACTUATION_ADOPT"]), needed=string(request.arguments.resultId);
elseif ismember(request.action,["PACKAGING_RUN","PACKAGING_COMPARE"]), needed=string(request.arguments.parentId);
end
keep=cellfun(@(r)string(r.id)==needed,records);
p.definition.results=reshape(records(keep),[],1); p.definition.derivations=cell(0,1);
request.project=p;
end
