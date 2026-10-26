function result=analyzeAntiRollBarKinematicSweep(input,z)
%ANALYZEANTIROLLBARKINEMATICSWEEP Geometry inspection independent of stiffness.
fsd.analysis.validatePreparedAntiRollBar(input);
assert(isnumeric(z)&&isreal(z)&&size(z,2)==2&&~isempty(z), ...
    'fsd:analysis:InvalidAntiRollBar','N-by-2 coordinates required.');
values=cell(size(z,1),1);
for k=1:size(z,1), values{k}=arbCoordinateCore(input,double(z(k,:)')); end
result=struct('schemaVersion',"0.23.0",'kind',"AntiRollBarKinematicSweep",'barIdentity',input.identity, ...
    'prepared',input,'requestedWheelTravel_m',double(z),'responses',{values});
end
