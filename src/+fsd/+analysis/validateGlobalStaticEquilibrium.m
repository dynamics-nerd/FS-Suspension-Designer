function valid = validateGlobalStaticEquilibrium(result, system)
%VALIDATEGLOBALSTATICEQUILIBRIUM Result-first, explicit matching source system.
prepared = fsd.analysis.prepareGlobalStaticSystem(system);
globalVerifyResult(prepared,result);
valid = true;
end
