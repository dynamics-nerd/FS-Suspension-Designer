function sweep=solveAntiRollBarSweep(bar,samples)
%SOLVEANTIROLLBARSWEEP Ordered pairs of native sources with branch continuation.
assert(iscell(samples)&&size(samples,2)==2&&~isempty(samples), ...
    'fsd:kinematics:InvalidAntiRollBar','N-by-2 source cells required, not a Cartesian product.');
states=cell(size(samples,1),1); reference=zeros(2,1); branches=zeros(2,1); following=true;
for k=1:size(samples,1)
    if ~following, states{k}=struct('kind',"AntiRollBarNotAttempted",'status',"CONTINUATION_FAILURE",'converged',false); continue; end
    states{k}=fsd.kinematics.solveAntiRollBar(bar,samples(k,:)',reference,branches);
    following=states{k}.converged;
    if following
        for side=1:2, reference(side)=states{k}.ends{side}.rotation_rad; branches(side)=states{k}.ends{side}.branchSign; end
    end
end
sweep=struct('schemaVersion',"0.23.0",'kind',"AntiRollBarKinematicSweep",'barIdentity',bar.identity, ...
    'sources',{samples},'states',{states});
end
