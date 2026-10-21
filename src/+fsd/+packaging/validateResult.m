function valid=validateResult(result)
%VALIDATERESULT Reconstruct geometry, native source, every check and aggregation.
assert(isstruct(result) && isscalar(result) && all(isfield(result,{'definition','geometry','plan','source'})), ...
    'fsd:packaging:InvalidResult','PackagingResult required.');
expected=fsd.packaging.evaluate(result.definition,result.geometry,result.plan,result.source);
assert(isequaln(result,expected),'fsd:packaging:InvalidResult','Packaging evidence differs from its declared inputs/source.');
valid=true;
end
