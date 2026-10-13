function e = synthesisAuditTestCall(space,u,id,errorId,stage)
%SYNTHESISAUDITTESTCALL Private BUMP fault injection; never a public solve adapter.
fsd.synthesis.validateDesignSpace(space);
if nargin<5, stage="BUMP"; end
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); original=pwd;
cleanup=onCleanup(@() cd(original)); cd(fullfile(root,'src','+fsd','+synthesis','private'));
if stage=="BUMP", e=evaluateCore(space,u,id,@failBump);
else, e=evaluateCore(space,u,id,@fsd.kinematics.solveBumpSweep,@failBump); end
    function sweep = failBump(varargin) %#ok<STOUT>
        error(char(errorId),'Injected BUMP boundary error; no completed sweep exists.');
    end
end
