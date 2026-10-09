function valid = validateGlobalStaticState(state, system)
%VALIDATEGLOBALSTATICSTATE Reconstruct every derived field; no trusted stored forces.
if ~isstruct(state) || ~isscalar(state) || ~isfield(state,"q")
    error("fsd:analysis:InvalidGlobalStaticState","Incomplete state.");
end
expected = fsd.analysis.evaluateGlobalStaticState(system,state.q);
if ~isequaln(state,expected)
    error("fsd:analysis:InvalidGlobalStaticState","Inconsistent reconstructed state.");
end
valid = true;
end
