function [keep, diagnostics] = rootsOutsideFlatIntervals(travel, flats)
%ROOTSOUTSIDEFLATINTERVALS Sorted-root sweep; O(F log F + R + F), inclusive ends.
% Keep original flat interval reporting (including gaps/order) unchanged.
ordered = sortrows(flats,[1,2]); keep = true(numel(travel),1);
cursor = 1; upper = -Inf; advances = 0;
for i = 1:numel(travel)
    while cursor <= size(ordered,1) && ordered(cursor,1) <= travel(i)
        upper = max(upper,ordered(cursor,2));
        cursor = cursor+1; advances = advances+1;
    end
    keep(i) = travel(i) > upper;
end
diagnostics = struct("algorithm","SORTED_INTERVAL_SWEEP", ...
    "rootComparisonCount",numel(travel),"intervalAdvanceCount",advances, ...
    "inputRootCount",numel(travel),"inputFlatIntervalCount",size(flats,1));
end
