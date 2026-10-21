classdef TestPackagingCandidates < matlab.unittest.TestCase
    properties
        Project
        Parent
    end
    methods (TestClassSetup)
        function storedHistory(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
            c=fsdui.Controller(); t.addTeardown(@()c.close()); c.run('DEMO',struct(),false);
            c.run('BUILD',struct('scope',"FRONT",'resultId',c.nextResultId()),false);
            c.run('REFERENCE_TARGETS',struct(),false);
            c.run('SYNTHESIS',struct('scenarioId',"UI_SEARCH_FL",'resultId',c.nextResultId()),false);
            t.Parent=c.LastValue; c.run('PACKAGING_DEMO',struct('cornerId',"FL"),false); t.Project=c.Project;
        end
    end
    methods (Test)
        function storedSeedAndSelectedCandidateWithoutSearch(t)
            c=fsdui.Controller(t.Project); t.addTeardown(@()c.close()); parent=t.Parent;
            a=struct('cornerId',"FL",'packagingId',"DEMO_PACKAGING",'parentId',parent.id, ...
                'selection',"CANDIDATE",'index',parent.nativePayload.selectedIndex,'mode',"BUMP",'resultId',"COMPARISON");
            profile clear; profile on; guard=onCleanup(@()profile('off'));
            c.run('PACKAGING_COMPARE',a,false); profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["solveBump","fsolve","evaluateSynthesisCandidate", ...
                "evaluateAxleCandidate","runInverseSearch","runAxleInverseSearch", ...
                "runSteeringInverseSearch","runActuationInverseSearch"])));
            % Historical validators intentionally replay the deterministic
            % controller against STORED records. Require that every controller
            % caller is such a validator, never a fresh physical search.
            controllers=find(endsWith(names,'boundedDirectSearch'));
            for controller=controllers(:)'
                parents=info.FunctionTable(controller).Parents;
                for caller=parents(:)'
                    callerName=string(info.FunctionTable(caller.Index).FunctionName);
                    t.verifyTrue(any(contains(callerName,["validateSynthesisResult","validateAxleSynthesisResult"])));
                end
            end
            t.verifyNumElements(c.LastValue,2);
            for j=1:2
                r=c.LastValue{j}; index=r.scenarioAtExecution.definition.inputs.candidateIndex;
                candidate=parent.nativePayload.search.records{index}.candidate;
                t.verifyEqual(fsd.model.geometryIdentity(r.nativePayload.geometry), ...
                    fsd.model.geometryIdentity(candidate.definitionSI.geometries{1}));
                t.verifyTrue(r.nativePayload.coverage.complete);
                compatibility=fsd.project.resultCompatibility(r,c.Project);
                t.verifyTrue(ismember(compatibility.status,["CURRENT_EXECUTION","REUSABLE_DEPENDENCIES"]));
            end
            matches=cellfun(@(r)r.id==parent.id,c.Project.definition.results);
            t.verifyEqual(c.Project.definition.results{matches},parent);
            source=c.LastValue{2}.scenarioAtExecution.definition.inputs.parent;
            t.verifyEqual(source.kind,"PackagingSourceReference");
            t.verifyEqual(source.sourceIdentity,parent.identity);
            t.verifyFalse(any(cellfun(@(s)s.definition.engine=="PACKAGING",source.dependencySnapshot.definition.scenarios)));
        end
        function adoptedGeometryUsesRegistryWithoutNewMotion(t)
            c=fsdui.Controller(t.Project); t.addTeardown(@()c.close()); parent=t.Parent;
            c.run('ADOPT',struct('resultId',parent.id,'index',parent.nativePayload.selectedIndex),false);
            before=c.Project;
            c.run('PACKAGING_RUN',struct('cornerId',"FL",'packagingId',"DEMO_PACKAGING",'parentId',"", ...
                'selection',"REGISTRY",'index',1,'mode',"NOMINAL",'resultId',"ADOPTED_PACK"),false);
            r=c.LastValue{1}; t.verifyEqual(r.nativePayload.geometry,before.definition.resources.geometries{1});
            t.verifyEmpty(r.nativePayload.source); t.verifyTrue(r.nativePayload.coverage.complete);
        end
    end
end
