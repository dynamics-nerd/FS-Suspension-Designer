function check = seedBumpCheckCore(seed,plan,sources)
%SEEDBUMPCHECKCORE Reconstruct stored native evidence and quality without a solve.
projectRequire(seed.nominalStatus=="VALID" && iscell(sources) && numel(sources)==numel(seed.geometries), ...
    'BUMP sources require a valid associated seed and one per corner.');
allReliable=true;
for j=1:numel(sources)
    g=seed.geometries{j}; source=sources{j};
    projectRequire(isequaln(source.geometry,g) && isequaln(source.sweep.requestedWheelTravel_m,plan.travel_m), 'Seed or grid association differs.');
    expected=seedBumpSource(g,source.sweep,plan);
    projectRequire(isequaln(workflowComparable(source),workflowComparable(expected)), 'Native seed source/analysis/quality differs.');
    allReliable=allReliable && source.sweep.allConverged && source.quality.allReliable && source.analysisStatus=="AVAILABLE";
end
status="SAMPLED_INCOMPLETE"; if allReliable, status="SAMPLED_PASS"; end
check=struct('schemaVersion',"0.17.0",'kind',"ParametricSeedBumpCheck",'seedIdentity',seed.identity, ...
    'plan',plan,'sources',{sources(:)},'status',status,'allReliable',allReliable, ...
    'identity',struct('seedIdentity',seed.identity,'plan',plan), ...
    'verificationDomain',"DECLARED_NATIVE_BUMP_SAMPLES_ONLY", ...
    'limitations',"Local conditioning and sampled convergence are not continuous or manufacturing certification.");
end
