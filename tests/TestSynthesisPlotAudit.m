classdef TestSynthesisPlotAudit < matlab.unittest.TestCase
    properties (TestParameter)
        Scenario={"SINGLE","FAILED","ONE_ELIGIBLE","MANY","NO_SCORE","GAPS","HARD_FAILED"}
        Appearance={"dark","light"}
    end
    methods (TestMethodSetup)
        function setup(t)
            old=path; visible=get(groot,'DefaultFigureVisible'); t.addTeardown(@() path(old));
            t.addTeardown(@() set(groot,'DefaultFigureVisible',visible));
            addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'src')); set(groot,'DefaultFigureVisible','off');
        end
    end
    methods (Test)
        function exportObjectsAndNativePng(t,Scenario,Appearance)
            [s,o]=synthesisFixture(); indices=[];
            switch Scenario
                case "SINGLE", r=fsd.synthesis.runInverseSearch(s,struct('maxEvaluations',1)); indices=1;
                case "FAILED", r=fsd.synthesis.runInverseSearch(synthesisFailureFixture(),struct('maxEvaluations',1));
                case "ONE_ELIGIBLE"
                    r=fsd.synthesis.runInverseSearch(synthesisFailureFixture("BUILDER"),struct('maxEvaluations',2));
                    t.verifyNumElements(r.feasibleIndices,1); indices=r.feasibleIndices;
                case "MANY", r=fsd.synthesis.runInverseSearch(s,o); indices=[1;r.selectedIndex];
                case "NO_SCORE"
                    d=s.specification.definitionSI; d.compositeScore=false;
                    s=fsd.synthesis.createDesignSpace(s.seed,fsd.model.createDesignSpecification(d),s.plan);
                    r=fsd.synthesis.runInverseSearch(s,struct('maxEvaluations',1)); indices=1;
                case "GAPS"
                    plan=s.plan; plan.travel_m=[0;.5;.6]; plan.solverOptions.MaxContinuationStep_m=1;
                    s=fsd.synthesis.createDesignSpace(s.seed,s.specification,plan);
                    r=fsd.synthesis.runInverseSearch(s,struct('maxEvaluations',1)); indices=1;
                case "HARD_FAILED"
                    d=s.specification.definitionSI; d.compositeScore=false; td=d.targets.definitionSI.targets{1}.definitionSI;
                    td.strength="HARD"; td.value=ones(3,1); td.tolerance=zeros(3,1);
                    d.targets=fsd.model.createSuspensionDesignTargets({fsd.model.createDesignTarget(td,'rad','m')});
                    s=fsd.synthesis.createDesignSpace(s.seed,fsd.model.createDesignSpecification(d),s.plan);
                    r=fsd.synthesis.runInverseSearch(s,struct('maxEvaluations',1)); indices=1;
            end
            folder=fullfile(fileparts(fileparts(mfilename('fullpath'))),'output','v0.12-audit-qa',Scenario);
            if isempty(indices), reports=synthesisPlotAuditCheck(r,folder,Appearance);
            else, reports=synthesisPlotAuditCheck(r,folder,Appearance,indices); end
            t.verifyNotEmpty(reports); t.verifyTrue(fsd.synthesis.validateSynthesisResult(r));
        end
        function combinedFailurePlotMatTamper(t)
            r=fsd.synthesis.runInverseSearch(synthesisFailureFixture(),struct('maxEvaluations',1));
            t.verifyTrue(fsd.synthesis.validateSynthesisResult(r)); t.verifyEmpty(r.feasibleIndices); t.verifyTrue(isnan(r.selectedIndex));
            folder=fullfile(fileparts(fileparts(mfilename('fullpath'))),'output','v0.12-audit-qa','COMBINED');
            synthesisPlotAuditCheck(r,folder,"dark"); file=string(tempname)+".mat"; t.addTeardown(@() delete(file));
            save(file,'r'); loaded=load(file,'r'); r=loaded.r; t.verifyTrue(fsd.synthesis.validateSynthesisResult(r));
            s=r.problem; plan=s.plan; plan.solverOptions.MaxIterations=1;
            r.problem=fsd.synthesis.createDesignSpace(s.seed,s.specification,plan);
            t.verifyError(@() fsd.synthesis.validateSynthesisResult(r),'fsd:synthesis:InvalidResult');
        end
        function comparisonAndImpossibleEmptyContract(t)
            s=synthesisFixture(); r=fsd.synthesis.runInverseSearch(s,struct('maxEvaluations',1));
            t.verifyError(@() fsd.synthesis.compareSynthesisCandidates(r,1),'fsd:analysis:InvalidDesignCandidate');
            t.verifyError(@() fsd.synthesis.runInverseSearch(s,struct('maxEvaluations',0)),'fsd:synthesis:InvalidInput');
            t.verifyError(@() fsd.synthesis.plotSynthesisResult(r,[1;1]),'fsd:synthesis:InvalidInput');
        end
    end
end
