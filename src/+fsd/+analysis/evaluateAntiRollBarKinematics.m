function result=evaluateAntiRollBarKinematics(prepared,z)
%EVALUATEANTIROLLBARKINEMATICS Inspect geometry without requiring spring data.
fsd.analysis.validatePreparedAntiRollBar(prepared);
r=fsd.model.antiRollBarReadiness(prepared.bar,'GEOMETRY');
assert(r.status=="READY",'fsd:analysis:AntiRollBarNotReady',strjoin([r.status;r.missing],'; '));
assert(isnumeric(z)&&isreal(z)&&numel(z)==2&&all(isfinite(z)), ...
    'fsd:analysis:InvalidAntiRollBar','Finite two-wheel SI coordinates required.');
result=arbCoordinateCore(prepared,double(z(:)));
end
