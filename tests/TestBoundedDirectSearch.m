classdef TestBoundedDirectSearch < matlab.unittest.TestCase
    % Mathematical expected values independent of the coordinate polling code.
    properties (TestParameter)
        Benchmark={"QUADRATIC_1D","QUADRATIC_2D","BOUNDARY","FLAT","MULTIMIN","INVALID_REGION","ACTIVE_HARD","MISSING"}
        BadOption={struct('maxEvaluations',0),struct('maxIterations',.5),struct('initialStep',NaN), ...
            struct('minimumStep',2),struct('stepReduction',1),struct('seeds',NaN),struct('stopAtScore',-1),struct('extra',1)}
    end
    methods (TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@() path(old)); addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'src'));
        end
    end
    methods (Test)
        function independentKnownCases(t,Benchmark)
            dimension=1; if Benchmark=="QUADRATIC_2D", dimension=2; end
            initial=.5*ones(dimension,1);
            options=struct('maxEvaluations',200,'maxIterations',100,'minimumStep',1/4096);
            if Benchmark=="MULTIMIN", options.seeds=.9; end
            s=fsd.synthesis.boundedDirectSearch(initial,true(dimension,1),options,@(u,id) benchmark(Benchmark,u,id),@(u) u);
            t.verifyLessThanOrEqual(s.evaluationCount,200); t.verifyLessThanOrEqual(s.iterations,100);
            if Benchmark=="MISSING"
                t.verifyEmpty(s.eligibleIndices); t.verifyTrue(isnan(s.selectedIndex)); return;
            end
            best=s.records{s.selectedIndex};
            if Benchmark=="FLAT"
                t.verifyEqual(best.score,2); t.verifyEqual(s.stopReason,"MINIMUM_STEP");
            else
                t.verifyLessThan(best.score,1e-6);
            end
            if Benchmark=="BOUNDARY"
                t.verifyEqual(s.keys{s.selectedIndex},1);
            elseif Benchmark=="ACTIVE_HARD"
                t.verifyGreaterThanOrEqual(s.keys{s.selectedIndex},.75);
            elseif Benchmark=="INVALID_REGION"
                t.verifyGreaterThanOrEqual(s.keys{s.selectedIndex},.4);
            end
        end
        function exhaustedBudget(t)
            s=fsd.synthesis.boundedDirectSearch(.5,true,struct('maxEvaluations',2),@(u,id) benchmark("QUADRATIC_1D",u,id),@(u) u);
            t.verifyEqual(s.evaluationCount,2); t.verifyEqual(s.stopReason,"MAX_EVALUATIONS");
        end
        function maxIterations(t)
            s=fsd.synthesis.boundedDirectSearch(.5,true,struct('maxIterations',1),@(u,id) benchmark("FLAT",u,id),@(u) u);
            t.verifyEqual(s.iterations,1); t.verifyEqual(s.stopReason,"MAX_ITERATIONS");
        end
        function scoreStop(t)
            s=fsd.synthesis.boundedDirectSearch(.25,true,struct('stopAtScore',0),@(u,id) benchmark("QUADRATIC_1D",u,id),@(u) u);
            t.verifyEqual(s.stopReason,"SCORE_TARGET_REACHED"); t.verifyEqual(s.evaluationCount,1);
        end
        function exactCache(t)
            options=struct('seeds',[.5;.5],'maxIterations',100);
            s=fsd.synthesis.boundedDirectSearch(.5,true,options,@(u,id) benchmark("FLAT",u,id),@(u) u);
            t.verifyGreaterThan(s.cacheHitCount,0); t.verifyEqual(s.evaluationCount,numel(unique(cell2mat(s.keys))));
        end
        function noFreeAxis(t)
            s=fsd.synthesis.boundedDirectSearch(0,false,struct(),@(u,id) benchmark("FLAT",u,id),@(u) u);
            t.verifyEqual(s.stopReason,"NO_FREE_VARIABLES"); t.verifyEqual(s.evaluationCount,1);
        end
        function deterministic(t)
            f=@(u,id) benchmark("QUADRATIC_2D",u,id);
            a=fsd.synthesis.boundedDirectSearch([.5;.5],[true;true],struct(),f,@(u) u);
            b=fsd.synthesis.boundedDirectSearch([.5;.5],[true;true],struct(),f,@(u) u);
            t.verifyEqual(a,b);
        end
        function invalidOptions(t,BadOption)
            t.verifyError(@() fsd.synthesis.boundedDirectSearch(.5,true,BadOption,@(u,id) benchmark("FLAT",u,id),@(u) u), ...
                'fsd:synthesis:InvalidInput');
        end
        function noScalarNoWinner(t)
            f=@(~,id) struct('eligible',true,'score',NaN,'reason',"NO_SCORE",'id',id);
            s=fsd.synthesis.boundedDirectSearch(.5,true,struct(),f,@(u) u);
            t.verifyTrue(isnan(s.selectedIndex)); t.verifyNotEmpty(s.eligibleIndices);
        end
    end
end

function record = benchmark(name,u,id)
eligible=true; score=NaN;
switch name
    case "QUADRATIC_1D", score=(u-.25)^2;
    case "QUADRATIC_2D", score=sum((u-[.25;.75]).^2);
    case "BOUNDARY", score=(u-1)^2;
    case "FLAT", score=2;
    case "MULTIMIN", score=((u-.2)*(u-.8))^2;
    case "INVALID_REGION", eligible=u>=.4; if eligible, score=(u-.75)^2; end
    case "ACTIVE_HARD", eligible=u>=.75; if eligible, score=(u-.75)^2; end
    case "MISSING", eligible=false;
end
record=struct('eligible',eligible,'score',score,'reason',name,'id',id);
end
