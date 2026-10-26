function result=analyzeAntiRollBarSweep(input,wheelTravel_m)
%ANALYZEANTIROLLBARSWEEP Explicit N-by-2 samples, no Cartesian expansion.
if isstruct(input)&&isfield(input,'kind')&&input.kind=="AntiRollBar", input=fsd.analysis.prepareAntiRollBar(input); end
fsd.analysis.validatePreparedAntiRollBar(input);
assert(isnumeric(wheelTravel_m)&&isreal(wheelTravel_m)&&size(wheelTravel_m,2)==2&& ...
    ~isempty(wheelTravel_m), ...
    'fsd:analysis:InvalidAntiRollBar','Real prescribed N-by-2 wheel coordinates required.');
z=double(wheelTravel_m); timer=tic; values=cell(size(z,1),1);
for k=1:size(z,1), values{k}=arbResponseCore(input,z(k,:)'); end
result=struct('schemaVersion',"0.23.0",'kind',"AntiRollBarSweep",'barIdentity',input.identity, ...
    'prepared',input,'requestedWheelTravel_m',z,'responses',{values},'elapsedTime_s',toc(timer));
end
