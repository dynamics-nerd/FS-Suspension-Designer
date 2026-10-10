function [candidate, result, model] = designEvaluationFixture(z, compression)
%DESIGNEVALUATIONFIXTURE Explicit ideal 1-D path, NOT a solved linkage claim.
% Inherited test law: ks=30000 N/m, preload=.02 m. Compression supplied by test.
if nargin < 1, z = [-.01;0;.01]; end
if nargin < 2, compression = .5*z; end
model = springDamperFixture();
result = fsd.analysis.analyzePrescribedSpringDamperPath(model,z,compression,0, ...
    struct("length","m","velocity","m/s"));
source = struct("id","MECH_FL","type","MECHANICAL","model",model,"result",result);
candidate = fsd.model.createDesignCandidate(struct("id","ANALYTICAL_A","sources",{{source}}));
end
