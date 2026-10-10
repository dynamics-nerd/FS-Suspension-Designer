function [value, canonicalUnit] = convertDesignUnits(value, quantity, unit)
%CONVERTDESIGNUNITS Explicit input/output boundary; never infer a quantity from units.
quantity = string(quantity); unit = string(unit);
if ~isscalar(quantity) || ~isscalar(unit) || ~isnumeric(value) || ~isreal(value)
    error("fsd:model:InvalidDesignDefinition","Numeric real values and scalar unit/quantity required.");
end
switch quantity
    case "LENGTH", units = ["m","mm"]; factors = [1,1e-3]; canonicalUnit = "m";
    case "ANGLE", units = ["rad","deg"]; factors = [1,pi/180]; canonicalUnit = "rad";
    case "FORCE", units = "N"; factors = 1; canonicalUnit = "N";
    case "STIFFNESS", units = ["N/m","N/mm"]; factors = [1,1000]; canonicalUnit = "N/m";
    case "DAMPING", units = ["N*s/m","N/(mm/s)"]; factors = [1,1000]; canonicalUnit = "N*s/m";
    case "MASS", units = "kg"; factors = 1; canonicalUnit = "kg";
    case "TIME", units = "s"; factors = 1; canonicalUnit = "s";
    case "FRACTION", units = ["1","%"]; factors = [1,.01]; canonicalUnit = "1";
    case "RATIO", units = "1"; factors = 1; canonicalUnit = "1";
    otherwise, error("fsd:model:InvalidDesignDefinition","Unknown physical quantity.");
end
i = find(unit == units);
if isempty(i), error("fsd:model:InvalidDesignDefinition","Unit incompatible with physical quantity."); end
value = double(value)*factors(i);
end
