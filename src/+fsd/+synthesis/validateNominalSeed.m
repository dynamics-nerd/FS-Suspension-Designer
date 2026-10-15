function valid = validateNominalSeed(geometry)
%VALIDATENOMINALSEED Reuse the historical builder's elementary wishbone checks.
% Empty design space; zero denotes its static reference, not a requested solve.
spec=fsd.model.createDesignSpecification(struct('id',"NOMINAL_SEED_CHECK"));
space=fsd.synthesis.createDesignSpace(geometry,spec,struct('travel_m',0));
fsd.synthesis.buildCandidateGeometry(space,space.initial_m);
valid=true;
end
