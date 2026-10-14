function space = rebuildActuationSpace(original,definition,plan,actuation,mechanical)
%REBUILDACTUATIONSPACE Canonical factories, never patch a derived identity.
if nargin<3, plan=original.plan; end
if nargin<4, actuation=original.seedActuation; end
if nargin<5, mechanical=original.seedMechanical; end
space=fsd.synthesis.createActuationDesignSpace(original.seed,actuation,mechanical, ...
    fsd.model.createDesignSpecification(definition),plan);
end
