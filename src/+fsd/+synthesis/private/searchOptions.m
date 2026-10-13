function options = searchOptions(input,count)
%SEARCHOPTIONS Software controls only; defaults have no engineering meaning.
options = struct('maxEvaluations',40,'maxIterations',40,'initialStep',.25, ...
    'minimumStep',1/1024,'stepReduction',.5,'seeds',zeros(0,count), ...
    'stopAtScore',[],'scoreImprovement',0);
requireSynthesis(isstruct(input) && isscalar(input),'Search options must be scalar struct.');
fields = string(fieldnames(input)); requireSynthesis(all(ismember(fields,string(fieldnames(options)))),'Unknown search option.');
for name=fields', options.(name)=input.(name); end
for name=["maxEvaluations","maxIterations"]
    v = options.(name); requireSynthesis(isnumeric(v) && isreal(v) && isscalar(v) && isfinite(v) && v>=1 && fix(v)==v,'Integer budget required.');
end
for name=["initialStep","minimumStep","stepReduction"]
    v = options.(name); requireSynthesis(isnumeric(v) && isreal(v) && isscalar(v) && isfinite(v) && v>0 && v<=1,'Step controls in (0,1] required.');
end
requireSynthesis(options.minimumStep<=options.initialStep && options.stepReduction<1,'Invalid step reduction/minimum.');
v = options.scoreImprovement;
requireSynthesis(isnumeric(v) && isreal(v) && isscalar(v) && isfinite(v) && v>=0,'Nonnegative improvement required.');
v = options.stopAtScore;
requireSynthesis(isempty(v) || (isnumeric(v) && isreal(v) && isscalar(v) && isfinite(v) && v>=0),'Invalid score stop.');
v = options.seeds;
requireSynthesis(isnumeric(v) && isreal(v) && ismatrix(v) && size(v,2)==count && all(isfinite(v),'all') && ...
    all(v>=0 & v<=1,'all'),'Seeds are rows in normalized coordinates.');
options.seeds = double(v);
end
