function converted = convertMechanicalUnits(value, quantity, fromUnit, toUnit)
%CONVERTMECHANICALUNITS Explicit v0.8 input/output conversion, no solver units.
validateattributes(value, {'numeric'}, {'real','finite'});
quantity = string(quantity); fromUnit = string(fromUnit); toUnit = string(toUnit);
if ~isscalar(quantity) || ~isscalar(fromUnit) || ~isscalar(toUnit)
    error("fsd:model:InvalidMechanicalUnit", "Units and quantity must be scalar.");
end
switch quantity
    case "length"
        names = ["m","mm"]; factors = [1,1e-3];
    case "velocity"
        names = ["m/s","mm/s"]; factors = [1,1e-3];
    case {"springRate","wheelRate"}
        names = ["N/m","N/mm"]; factors = [1,1e3];
    case "dampingCoefficient"
        names = ["N*s/m","N/(mm/s)"]; factors = [1,1e3];
    otherwise
        error("fsd:model:InvalidMechanicalUnit", "Unsupported quantity.");
end
a = find(names == fromUnit); b = find(names == toUnit);
if isempty(a) || isempty(b)
    error("fsd:model:InvalidMechanicalUnit", "Unsupported unit for %s.", quantity);
end
converted = double(value) * (factors(a)/factors(b));
if any(~isfinite(converted), "all")
    error("fsd:model:InvalidMechanicalValue", "Conversion overflow.");
end
end
