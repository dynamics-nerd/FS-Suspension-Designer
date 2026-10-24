function report=readiness(tire,states,request)
%READINESS Sample/channel diagnostics; no project, UI or external toolbox.
if nargin<3, request=struct(); end
fsd.tire.validate(tire); [states,request]=evaluationInput(states,request);
r=responseCore(tire,states,request); selected=ismember(r.channels,request.channels);
s=r.status(:,selected); status="READY";
missing=unique(r.diagnostics(r.status=="MISSING_DATA"));
if any(s=="MISSING_DATA",'all'), status="MISSING_DATA";
elseif any(s=="INVALID_INPUT",'all'), status="INVALID_INPUT";
elseif any(s=="NOT_SUPPORTED",'all'), status="UNSUPPORTED";
elseif request.domainPolicy=="REJECT"&&any(~ismember(s,["AVAILABLE","NO_CONTACT"]),'all'), status="OUT_OF_DOMAIN";
end
report=struct('status',status,'missing',missing(:),'diagnostics',unique(r.diagnostics(strlength(r.diagnostics)>0)), ...
    'sampleStatus',r.status,'channels',r.channels,'request',request);
end
