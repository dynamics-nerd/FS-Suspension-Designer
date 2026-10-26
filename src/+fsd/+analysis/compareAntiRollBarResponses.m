function comparison=compareAntiRollBarResponses(first,second)
%COMPAREANTIROLLBARRESPONSES Preserve identities; no equivalence from one rate.
assert(isstruct(first)&&isstruct(second)&&first.kind=="AntiRollBarSweep"&&second.kind=="AntiRollBarSweep", ...
    'fsd:analysis:InvalidAntiRollBar','Two complete stored ARB sweeps required.');
same=isequaln(first.requestedWheelTravel_m,second.requestedWheelTravel_m);
comparison=struct('compatibleConditions',same,'firstIdentity',first.barIdentity,'secondIdentity',second.barIdentity, ...
    'energyDifference_J',[],'resistanceDifference_N',[],'diagnostics',"Different ordered wheel conditions; no overlay or equivalence.");
if ~same, return; end
comparison.energyDifference_J=nan(numel(first.responses),1); comparison.resistanceDifference_N=nan(numel(first.responses),2);
for k=1:numel(first.responses)
    a=first.responses{k}; b=second.responses{k};
    if a.available&&b.available
        comparison.energyDifference_J(k)=b.energy_J-a.energy_J;
        comparison.resistanceDifference_N(k,:)=(b.resistance_N-a.resistance_N)';
    end
end
comparison.diagnostics="Same prescribed wheel coordinates; results retain different resources, sources and hypotheses.";
end
