function path = validateMechanicalSweepSource(model, source, actuation)
%VALIDATEMECHANICALSWEEPSOURCE Validate full upstream payload once at boundary.
fsd.model.validateSpringDamperModel(model);
if ~isstruct(source) || ~isscalar(source) || ~isfield(source,"kind")
    invalid("Invalid source.");
end
if isequal(source.kind,"ActuationSweep")
    if ~all(isfield(source,["sweep","analysis"])) || isempty(actuation)
        invalid("Actuation source and geometry are required.");
    end
    fsd.analysis.validateActuationSweepAnalysis(source.analysis,actuation,source.sweep);
    if ~isequal(model.actuationIdentity,source.sweep.actuationIdentity)
        error("fsd:analysis:SpringDamperIdentityMismatch","Model belongs to another actuation.");
    end
    sweep = source.sweep;
    path = struct("requestedWheelTravel_m",sweep.requestedWheelTravel_m, ...
        "achievedWheelTravel_m",sweep.achievedWheelTravel_m, ...
        "damperLength_m",sweep.damperLength_m,"damperCompression_m",sweep.damperCompression_m, ...
        "converged",sweep.converged, ...
        "isIllConditioned",reshape([sweep.results.isIllConditioned],[],1));
elseif isequal(source.kind,"PrescribedDamperPath")
    if ~all(isfield(source,["wheelTravel_m","damperCompression_m"]))
        invalid("Incomplete prescribed path.");
    end
    z = source.wheelTravel_m; c = source.damperCompression_m;
    if ~isnumeric(z) || ~isreal(z) || ~iscolumn(z) || isempty(z) || ...
            ~isnumeric(c) || ~isreal(c) || ~isequal(size(z),size(c)) || ...
            any(~isfinite(z)) || any(~isfinite(c))
        invalid("Path must have matching finite columns.");
    end
    length = model.derivedStaticGeometry.damperStaticLength_m-c;
    if any(length <= 0) || any(abs(c(z == 0)) > 64*eps(max([abs(c);1])))
        invalid("Nonpositive damper length or inconsistent nominal compression.");
    end
    path = struct("requestedWheelTravel_m",z,"achievedWheelTravel_m",z, ...
        "damperLength_m",length,"damperCompression_m",c, ...
        "converged",true(size(z)),"isIllConditioned",false(size(z)));
else
    invalid("Unsupported mechanical source kind.");
end
end

function invalid(message)
error("fsd:analysis:InvalidSpringDamperAnalysis",message);
end
