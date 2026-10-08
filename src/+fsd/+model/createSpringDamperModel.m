function model = createSpringDamperModel(actuation, definition, units)
%CREATESPRINGDAMPERMODEL Create an optional ideal COILOVER in canonical SI.
% definition.spring: modelType, rate, freeLength, preloadCompression,
% optional solidHeight. definition.damper: modelType, compressionCoefficient
% and reboundCoefficient OR compressionTable/reboundTable [speed, force_N];
% optional minimumLength/maximumLength. units: length, springRate,
% dampingCoefficient, velocity. Bounds absent => UNKNOWN, not certified safe.
fsd.model.validateActuationGeometry(actuation);
if ~isstruct(definition) || ~isscalar(definition) || ...
        ~all(isfield(definition, ["configuration","spring","damper"])) || ...
        ~isstruct(units) || ~isscalar(units) || ...
        ~all(isfield(units, ["length","springRate","dampingCoefficient","velocity"]))
    error("fsd:model:InvalidSpringDamperModel", "Incomplete definition or units.");
end
% Validate even unit tokens whose quantity is unused by a particular law.
fsd.model.convertMechanicalUnits(0,"length",units.length,"m");
fsd.model.convertMechanicalUnits(0,"springRate",units.springRate,"N/m");
fsd.model.convertMechanicalUnits(0,"dampingCoefficient",units.dampingCoefficient,"N*s/m");
fsd.model.convertMechanicalUnits(0,"velocity",units.velocity,"m/s");
s = definition.spring; d = definition.damper;
spring = struct("modelType",string(s.modelType), ...
    "rate_N_per_m",fsd.model.convertMechanicalUnits(s.rate,"springRate",units.springRate,"N/m"), ...
    "freeLength_m",lengthValue(s.freeLength,units), ...
    "preloadCompression_m",lengthValue(s.preloadCompression,units), ...
    "solidHeight_m",optionalLength(s,"solidHeight",units));
damper = struct("modelType",string(d.modelType), ...
    "compressionCoefficient_Ns_per_m",[], "reboundCoefficient_Ns_per_m",[], ...
    "compressionTable",[], "reboundTable",[], ...
    "minimumLength_m",optionalLength(d,"minimumLength",units), ...
    "maximumLength_m",optionalLength(d,"maximumLength",units));
switch damper.modelType
    case "LINEAR_ASYMMETRIC"
        damper.compressionCoefficient_Ns_per_m = fsd.model.convertMechanicalUnits( ...
            d.compressionCoefficient,"dampingCoefficient",units.dampingCoefficient,"N*s/m");
        damper.reboundCoefficient_Ns_per_m = fsd.model.convertMechanicalUnits( ...
            d.reboundCoefficient,"dampingCoefficient",units.dampingCoefficient,"N*s/m");
    case "TABULATED_FORCE_VELOCITY"
        damper.compressionTable = convertTable(d.compressionTable,units);
        damper.reboundTable = convertTable(d.reboundTable,units);
    otherwise
        error("fsd:model:InvalidSpringDamperModel", "Unsupported damper law.");
end
metadata = struct;
if isfield(definition,"metadata"), metadata = definition.metadata; end
model = struct("schemaVersion","0.8.0","kind","SpringDamperModel", ...
    "cornerId",actuation.cornerId,"actuationIdentity",actuation.identity, ...
    "configuration",string(definition.configuration),"spring",spring, ...
    "damper",damper,"derivedStaticGeometry",struct,"metadata",metadata);
model.derivedStaticGeometry = springDamperStaticGeometry(model);
model.identity = fsd.model.springDamperIdentity(model);
fsd.model.validateSpringDamperModel(model);
end

function value = lengthValue(value,units)
value = fsd.model.convertMechanicalUnits(value,"length",units.length,"m");
end

function value = optionalLength(definition,name,units)
value = [];
if isfield(definition,name) && ~isempty(definition.(name))
    value = lengthValue(definition.(name),units);
end
end

function value = convertTable(value,units)
validateattributes(value,{'numeric'},{'real','finite','2d','ncols',2});
value = double(value);
value(:,1) = fsd.model.convertMechanicalUnits(value(:,1),"velocity",units.velocity,"m/s");
end
