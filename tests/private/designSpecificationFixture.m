function specification = designSpecificationFixture(target, score)
%DESIGNSPECIFICATIONFIXTURE Standalone single-target specification.
if nargin < 2, score = false; end
specification = fsd.model.createDesignSpecification(struct("id","TEST_SPEC", ...
    "targets",fsd.model.createSuspensionDesignTargets({target}),"compositeScore",score));
end
