function search = boundedDirectSearch(initial,active,input,evaluator,keyFunction)
%BOUNDEDDIRECTSEARCH Deterministic box polling, exact-key cache, no toolbox.
% Generic mathematical controller. EVALUATOR(u,id) returns eligible/score/reason.
% No feasibility penalty: ineligible records never become selected solutions.
initial = double(initial(:)); active = active(:); count = numel(initial);
requireSynthesis(islogical(active) && numel(active)==count && all(isfinite(initial)) && ...
    all(initial>=0 & initial<=1) && all(initial(~active)==0),'Invalid normalized initial/active axes.');
options = searchOptions(input,count);
requireSynthesis(all(options.seeds(:,~active)==0,'all'),'Frozen seed axes must be zero.');
requireSynthesis(isa(evaluator,'function_handle') && isa(keyFunction,'function_handle'),'Evaluator and key callbacks required.');
seeds = [initial';options.seeds]; records = cell(0,1); keys = cell(0,1); history = cell(0,1);
stop = "SEEDS_COMPLETED"; iterations = 0; stopped = false;
for s=1:size(seeds,1)
    center = seeds(s,:)'; incumbent = 0; step = options.initialStep;
    [index,exhausted] = visit(center,0,s,step,incumbent);
    if exhausted, stop="MAX_EVALUATIONS"; break; end
    incumbent = index;
    if reached(records{index}), stop="SCORE_TARGET_REACHED"; break; end
    if ~any(active), stop="NO_FREE_VARIABLES"; break; end
    while step>=options.minimumStep
        if iterations>=options.maxIterations, stop="MAX_ITERATIONS"; stopped=true; break; end
        iterations = iterations+1; improved = false; origin = center;
        for axis=find(active)'
            for direction=[-1,1]
                trial = origin; trial(axis) = min(1,max(0,origin(axis)+direction*step));
                [index,exhausted] = visit(trial,iterations,s,step,incumbent);
                if exhausted, stop="MAX_EVALUATIONS"; stopped=true; break; end
                if better(records{index},records{incumbent})
                    incumbent=index; center=trial; improved=true;
                end
                if reached(records{index}), stop="SCORE_TARGET_REACHED"; stopped=true; break; end
            end
            if stopped, break; end
        end
        if stopped, break; end
        if ~improved, step=step*options.stepReduction; end
    end
    if stopped, break; end
    stop="MINIMUM_STEP";
end
eligible = find(cellfun(@(r) r.eligible,records)); selected = NaN;
scored = eligible(cellfun(@(r) isfinite(r.score),records(eligible)));
if ~isempty(scored)
    [~,i] = min(cellfun(@(r) r.score,records(scored))); selected=scored(i);
end
search = struct('options',options,'initial',initial,'active',active,'records',{records}, ...
    'keys',{keys},'history',{history},'eligibleIndices',eligible(:),'selectedIndex',selected, ...
    'stopReason',stop,'iterations',iterations,'evaluationCount',numel(records), ...
    'attemptCount',numel(history),'cacheHitCount',sum(cellfun(@(h) h.cacheHit,history)));

    function [index,exhausted] = visit(u,iteration,seedIndex,currentStep,previous)
        key = keyFunction(u); index = find(cellfun(@(v) isequaln(v,key),keys),1); hit=~isempty(index);
        exhausted = ~hit && numel(records)>=options.maxEvaluations;
        if exhausted, index=0; return; end
        if ~hit
            index=numel(records)+1; record=evaluator(u,index);
            requireSynthesis(isstruct(record) && isscalar(record) && islogical(record.eligible) && isscalar(record.eligible) && ...
                isnumeric(record.score) && isreal(record.score) && isscalar(record.score) && ...
                (isnan(record.score) || (isfinite(record.score) && record.score>=0)),'Invalid evaluator record.');
            records{index,1}=record; keys{index,1}=key;
        end
        accepted = previous==0;
        if previous~=0, accepted=better(records{index},records{previous}); end
        criterion="NO_ELIGIBLE_IMPROVEMENT";
        if previous==0
            criterion="SEED_START";
        elseif accepted && ~records{previous}.eligible
            criterion="HARD_FEASIBILITY_FOUND";
        elseif accepted
            criterion="EXPLICIT_SOFT_SCORE_IMPROVEMENT";
        end
        history{end+1,1}=struct('attemptId',numel(history)+1,'evaluationId',index,'u',u, ...
            'key',key,'iteration',iteration,'seedIndex',seedIndex,'step',currentStep, ...
            'cacheHit',hit,'accepted',accepted,'acceptanceCriterion',criterion,'reason',records{index}.reason);
    end
    function yes = better(a,b)
        yes = a.eligible && (~b.eligible || (isfinite(a.score) && isfinite(b.score) && a.score < b.score-options.scoreImprovement));
    end
    function yes = reached(a)
        yes = ~isempty(options.stopAtScore) && a.eligible && isfinite(a.score) && a.score<=options.stopAtScore;
    end
end
