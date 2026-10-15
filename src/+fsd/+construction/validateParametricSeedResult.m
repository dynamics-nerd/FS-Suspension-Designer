function valid = validateParametricSeedResult(result)
%VALIDATEPARAMETRICSEEDRESULT Reconstruct all coordinates/provenance without solves.
try
    seedRequire(isstruct(result) && isscalar(result) && ...
        isequaln(result,fsd.construction.buildParametricSeed(result.definition,result.referenceParameters)), ...
        'Parametric seed result, associations or evidence differ from original inputs.');
catch cause
    exception=MException('fsd:construction:InvalidSeedResult','Parametric seed evidence cannot be reconstructed.');
    throwAsCaller(addCause(exception,cause));
end
valid=true;
end
