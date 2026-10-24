function response=evaluate(tire,states,request)
%EVALUATE Native stationary forces. Unavailable channels are NaN plus status.
if nargin<3, request=struct(); end
fsd.tire.validate(tire); [states,request]=evaluationInput(states,request);
response=responseCore(tire,states,request);
if request.domainPolicy=="REJECT"
    selected=ismember(response.channels,request.channels);
    assert(all(ismember(response.status(:,selected),["AVAILABLE","NO_CONTACT"]),'all'), ...
        'fsd:tire:NotReady','Requested samples/channels are unavailable; inspect readiness.');
end
end
