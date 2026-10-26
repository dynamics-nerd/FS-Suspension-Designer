function response=evaluateAntiRollBar(input,wheelTravel_m)
%EVALUATEANTIROLLBAR Coupled energy/resistance, never two independent springs.
if isstruct(input)&&isfield(input,'kind')&&input.kind=="AntiRollBar"
    input=fsd.analysis.prepareAntiRollBar(input);
end
fsd.analysis.validatePreparedAntiRollBar(input);
assert(isnumeric(wheelTravel_m)&&isreal(wheelTravel_m)&&numel(wheelTravel_m)==2&&all(isfinite(wheelTravel_m)), ...
    'fsd:analysis:InvalidAntiRollBar','Two finite SI wheel coordinates required.');
response=arbResponseCore(input,double(wheelTravel_m(:)));
end
