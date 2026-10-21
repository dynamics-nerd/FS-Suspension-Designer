classdef TestPackagingProject < matlab.unittest.TestCase
    properties
        Project
        Bump
        Packaging
    end
    methods (TestClassSetup)
        function nativeProject(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'));
            [d,g]=packagingMotionFixture(.04); t.Packaging=d;
            concept=fsd.project.createVehicleConcept(struct('id',"PACKAGING_TEST"));
            scenario=fsd.project.createEngineeringScenario(struct('id',"BUMP_SOURCE",'engine',"BUMP", ...
                'scope',fsd.model.designScope('CORNER','FL'),'plan',struct('travel_m',[0;.04;.08])));
            resources=struct('geometries',{{g}});
            p=fsd.project.createEngineeringProject(struct('concept',concept,'resources',resources,'scenarios',{{scenario}}));
            r=fsd.project.runEngineeringScenario(p,"BUMP_SOURCE","BUMP_EVIDENCE");
            p=fsd.project.attachEngineeringResult(p,r); t.Bump=r;
            resources=p.definition.resources; resources.packaging={d};
            t.Project=fsd.project.reviseEngineeringProject(p,struct('resources',resources));
        end
    end
    methods (Test)
        function packagingOnlyRevisionRetainsBump(t)
            r=fsd.project.resultCompatibility(t.Bump,t.Project);
            t.verifyEqual(r.status,"REUSABLE_DEPENDENCIES");
            t.verifyEqual(t.Project.definition.results{1},t.Bump);
            older=t.Bump.projectAtExecution;
            t.verifyFalse(isfield(older.definition.resources,'packaging'),'Do not invent packaging in older projects.');
        end
        function boundedSourcePreservesNativeOriginAndCompatibility(t)
            source=fsd.project.createPackagingSource(t.Bump);
            t.verifyEqual(source.sourceIdentity,t.Bump.identity);
            t.verifyEqual(source.nativePayload,t.Bump.nativePayload);
            t.verifyEqual(source.prepared,t.Bump.prepared);
            t.verifyFalse(isfield(source,'projectAtExecution'));
            t.verifyFalse(isfield(source.dependencySnapshot.definition.resources,'packaging'));
            t.verifyEmpty(source.dependencySnapshot.definition.results);
            compatibility=fsd.project.resultCompatibility(source,t.Project);
            t.verifyEqual(compatibility.status,"REUSABLE_DEPENDENCIES");
            bad=source; bad.prepared.context=struct();
            t.verifyError(@()fsd.project.validatePackagingSource(bad),'fsd:project:InvalidInput');
            bad=source; bad.sourceIdentity.projectRevision=bad.sourceIdentity.projectRevision+1;
            t.verifyError(@()fsd.project.validatePackagingSource(bad),'fsd:project:InvalidInput');
        end
        function sampledExecutionRevisionAndMat(t)
            plan=struct('mode',"BUMP",'requested_m',[0;.04;.08]);
            scenario=fsd.project.createPackagingScenario('PACK_FL','FL','SOFTWARE_CASE',plan,t.Bump,'REGISTRY',[]);
            scenarios=[t.Project.definition.scenarios;{scenario}];
            p=fsd.project.reviseEngineeringProject(t.Project,struct('scenarios',{scenarios}));
            before=p; profile clear; profile on;
            ready=fsd.project.designReadiness(p,"PACK_FL");
            result=fsd.project.runEngineeringScenario(p,"PACK_FL","PACKAGE_RESULT");
            p=fsd.project.attachEngineeringResult(p,result);
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            file=string(fullfile(folder.Folder,'packaging.mat'));
            fsd.project.saveEngineeringProject(p,file,false); restored=fsd.project.loadEngineeringProject(file);
            profile off; profiling=profile('info'); names=string({profiling.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["solveBump","fsolve","solveActuation","boundedDirectSearch"])));
            t.verifyEqual(ready.status,"READY"); t.verifyEqual(result.nativePayload.status,"COLLISION_DETECTED");
            t.verifyEqual(restored,p); t.verifyEqual(result.projectRevision,before.definition.revision);
            compatibility=fsd.project.resultCompatibility(result,p); t.verifyEqual(compatibility.status,"CURRENT_EXECUTION");
            resources=p.definition.resources; input=resources.packaging{1}.definitionSI;
            input.pairs{1}.requiredClearance_m=.006;
            resources.packaging={fsd.packaging.createDefinition(input)};
            changed=fsd.project.reviseEngineeringProject(p,struct('resources',resources));
            compatibility=fsd.project.resultCompatibility(result,changed); t.verifyEqual(compatibility.status,"STALE");
            compatibility=fsd.project.resultCompatibility(t.Bump,changed); t.verifyEqual(compatibility.status,"REUSABLE_DEPENDENCIES");
            t.verifyEqual(changed.definition.results,p.definition.results);
            descriptor=fsd.project.reviseEngineeringProject(p,struct('description',"Independent text"));
            compatibility=fsd.project.resultCompatibility(result,descriptor); t.verifyEqual(compatibility.status,"REUSABLE_DEPENDENCIES");
        end
        function nominalNoHiddenMotionAndMissingResource(t)
            plan=struct('mode',"NOMINAL",'requested_m',[]);
            s=fsd.project.createPackagingScenario('PACK_FL','FL','SOFTWARE_CASE',plan,[],'REGISTRY',[]);
            p=fsd.project.reviseEngineeringProject(t.Project,struct('scenarios',{{s}}));
            r=fsd.project.runEngineeringScenario(p,"PACK_FL","NOMINAL_RESULT");
            t.verifyEqual(r.nativePayload.status,"CLEAR_SAMPLED"); t.verifyEmpty(r.nativePayload.source);
            d=s.definition; d.inputs.packagingId="UNDECLARED";
            s=fsd.project.createEngineeringScenario(d);
            p=fsd.project.reviseEngineeringProject(p,struct('scenarios',{{s}}));
            readiness=fsd.project.designReadiness(p,"PACK_FL"); t.verifyEqual(readiness.status,"MISSING_DATA");
        end
        function changedGeometryMakesStoredParentStale(t)
            s=fsd.project.createPackagingScenario('PACK_FL','FL','SOFTWARE_CASE', ...
                struct('mode',"BUMP",'requested_m',[0;.04;.08]),t.Bump,'REGISTRY',[]);
            p=fsd.project.reviseEngineeringProject(t.Project,struct('scenarios',{{t.Project.definition.scenarios{1};s}}));
            r=fsd.project.runEngineeringScenario(p,"PACK_FL","PACKAGE_RESULT");
            resources=p.definition.resources; g=resources.geometries{1}; points=g.hardpoints.xyz_m;
            points(1,3)=points(1,3)+.005;
            resources.geometries={fsd.model.createDoubleWishboneGeometry('FL',g.hardpoints.ids,points,'m',g.wheel.wheelAxis,g.hardpoints)};
            changed=fsd.project.reviseEngineeringProject(p,struct('resources',resources));
            c=fsd.project.resultCompatibility(r,changed); t.verifyEqual(c.status,"STALE");
            readiness=fsd.project.designReadiness(changed,"PACK_FL"); t.verifyEqual(readiness.status,"BLOCKED_BY_DEPENDENCY");
        end
    end
end
