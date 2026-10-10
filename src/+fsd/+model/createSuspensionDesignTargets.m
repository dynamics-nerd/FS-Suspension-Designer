function targets = createSuspensionDesignTargets(targetCells)
%CREATESUSPENSIONDESIGNTARGETS Serializable independent collection of user objectives.
targets = designTargetsCore(struct("targets",{targetCells}));
end
