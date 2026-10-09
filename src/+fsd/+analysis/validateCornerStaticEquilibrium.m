function valid = validateCornerStaticEquilibrium(result, model, actuation, mechanical)
%VALIDATECORNERSTATICEQUILIBRIUM Reconstruct every root, field, status and bracket.
id = "fsd:analysis:InvalidCornerEquilibrium";
if ~isstruct(result) || ~isscalar(result) || ~all(isfield(result, ...
        ["sourceModel","sourceActuation","sourceMechanical","targetSupport_N","options","elapsedTime_s"]))
    error(id,"Invalid local equilibrium result.");
end
if nargin < 2, model = result.sourceModel; end
if nargin < 3, actuation = result.sourceActuation; end
if nargin < 4, mechanical = result.sourceMechanical; end
options = cornerEquilibriumInputs(model,actuation,mechanical,result.targetSupport_N,result.options);
expected = cornerEquilibriumCore(model,actuation,mechanical,result.targetSupport_N,options);
if ~isnumeric(result.elapsedTime_s) || ~isscalar(result.elapsedTime_s) || ...
        ~isfinite(result.elapsedTime_s) || result.elapsedTime_s < 0 || ...
        ~isequaln(rmfield(result,"elapsedTime_s"),rmfield(expected,"elapsedTime_s"))
    error(id,"Inconsistent equilibrium payload or association.");
end
valid = true;
end
