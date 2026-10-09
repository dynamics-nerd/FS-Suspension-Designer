function report = verifyV10()
%VERIFYV10 Ten examples, Analyzer, DAG, plotted output and global performance.
root = fileparts(fileparts(mfilename("fullpath"))); oldPath = path;
cleanup = onCleanup(@() path(oldPath)); addpath(root,fullfile(root,"src"),fullfile(root,"examples"));
assert(strcmp(fsd.version,"0.10.0"));
historical = verifyV08; % eight examples, all .m Analyzer and qualified-call DAG
vehicleStaticEquilibriumExample(false);
fprintf("EXAMPLE_OK=vehicleStaticEquilibriumExample\n");
e = globalStaticEquilibriumExample(false);
assert(isfinite(e.result.selectedIndex),"Real four-corner example must converge.");
fprintf("EXAMPLE_OK=globalStaticEquilibriumExample\n");
visibility = get(groot,"defaultFigureVisible"); set(groot,"defaultFigureVisible","off");
figureCleanup = onCleanup(@() set(groot,"defaultFigureVisible",visibility));
figures = fsd.analysis.plotGlobalStaticEquilibrium(e.system,e.result);
assert(numel(figures) == 3 && all(isgraphics(figures)));
close(figures);
[s,o] = globalStaticFixture;
benchmark = fsd.analysis.solveGlobalStaticEquilibrium(s,zeros(7,1),o);
q = benchmark.alternatives{1}.state;
assert(norm(q.q-[-.005;zeros(6,1)],inf) < 1e-8);
performance = fsd.analysis.benchmarkGlobalStaticEquilibrium(e.system,[-.005;zeros(6,1)],e.options);
fprintf("GLOBAL_PERFORMANCE:\n"); disp(performance);
fprintf("GLOBAL_BENCHMARK q:\n"); disp(q.q'); fprintf("GLOBAL_BENCHMARK normals:\n"); disp(q.normalForces_N');
fprintf("GLOBAL_BENCHMARK stability=%s\n",benchmark.alternatives{1}.stability);
report = struct("historical",historical,"exampleCount",10,"plotFigures",3, ...
    "globalBenchmark",q,"performance",performance,"version",fsd.version);
end
