function report=benchmarkPackaging()
%BENCHMARKPACKAGING Explicit deterministic diagnostic, never auto-enable parfor.
% Own only the newly-created local process pool; preserve an existing pool.
root=fileparts(fileparts(mfilename('fullpath'))); old=path;
cleanup=onCleanup(@()path(old)); addpath(fullfile(root,'src'));
existing=gcp('nocreate'); assert(isempty(existing),'fsd:packaging:BenchmarkPool','Run with no active pool to measure startup/ownership clearly.');
started=tic; pool=parpool('Processes',2); startup_s=toc(started);
poolCleanup=onCleanup(@()delete(pool));
[definition,g]=packagingMotionFixture(.04);
source=fsd.kinematics.solveBumpSweep(g,[0;.04;.08],'m'); plan=struct('mode',"BUMP",'requested_m',[0;.04;.08]);
expected=fsd.packaging.evaluate(definition,g,plan,source);
% Explicit MAT serialization surrogate and actual PCT transfer counters.
folder=tempname; mkdir(folder); file=fullfile(folder,'snapshot.mat');
fileCleanup=onCleanup(@()removeTemporary(file,folder));
started=tic; save(file,'definition','g','plan','source','-v7'); serialization_s=toc(started);
info=dir(file); started=tic; restored=load(file); deserialization_s=toc(started);
assert(isequaln(restored.definition,definition) && isequaln(restored.source,source));
ticBytes(pool); started=tic;
future=parfeval(pool,@fsd.packaging.evaluate,1,definition,g,plan,source); actual=fetchOutputs(future);
transferAndEvaluation_s=toc(started); transferred=tocBytes(pool);
assert(isequaln(actual,expected));
a=packagingVolumeFixture('A','OBB',[1 2 3],[0 0 0]);
b=packagingVolumeFixture('B','OBB',[2 1 3],[4 .3 .7],[cos(.4) -sin(.4) 0;sin(.4) cos(.4) 0;0 0 1]);
reference=fsd.packaging.distance(a,b); sizes=[4 128 4096]; sequential_s=zeros(numel(sizes),3); parallel_s=sequential_s;
% Warm worker code paths, exclude startup from warmed batch timings.
f=parfeval(pool,@fsd.packaging.distance,1,a,b); fetchOutputs(f);
for k=1:numel(sizes)
    n=sizes(k);
    for repetition=1:3
        serial=cell(n,1); concurrent=cell(n,1); started=tic;
        for j=1:n, serial{j}=fsd.packaging.distance(a,b); end
        sequential_s(k,repetition)=toc(started); started=tic;
        parfor j=1:n, concurrent{j}=fsd.packaging.distance(a,b); end
        parallel_s(k,repetition)=toc(started);
        assert(isequaln(serial,concurrent) && all(cellfun(@(v)isequaln(v,reference),serial)));
    end
end
report=struct('poolWorkers',2,'startup_s',startup_s,'snapshotBytes',info.bytes, ...
    'serialization_s',serialization_s,'deserialization_s',deserialization_s, ...
    'transferAndEvaluation_s',transferAndEvaluation_s,'transferred',transferred, ...
    'batchSizes',sizes,'sequential_s',sequential_s,'parallel_s',parallel_s, ...
    'deterministic',true,'productionParallelKernelEnabled',false);
disp(report); disp(table(sizes',median(sequential_s,2),median(parallel_s,2), ...
    'VariableNames',{'Pairs','SequentialMedian_s','ParallelMedian_s'}));
end
function removeTemporary(file,folder)
if isfile(file), delete(file); end
if isfolder(folder), rmdir(folder); end
end
