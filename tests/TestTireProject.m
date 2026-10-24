classdef TestTireProject < matlab.unittest.TestCase
    properties
        Project
        Global
        Tire
        Definition
    end
    methods(TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
            [p,d]=globalStaticGuidedInputs; td=tireCharacterizationInputs;
            [p,tire]=fsd.project.registerTire(p,td); p=fsd.project.assignTires(p,assignments(tire));
            d.inputs=struct('tireSource',"LIBRARY_ASSIGNMENTS"); p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
            [r,p]=fsd.project.runEngineeringScenario(p,d.id,'LIBRARY_GLOBAL');
            t.Project=p; t.Global=r; t.Tire=tire; t.Definition=d;
        end
    end
    methods(Test)
        function exactNativeVerticalAndNominalResult(t)
            r=t.Global; t.verifyEqual(r.nativePayload.equilibrium.selectedIndex,1);
            t.verifyEqual(r.nativePayload.equilibrium.alternatives{1}.state.normalForces_N,500*ones(4,1),'AbsTol',.05);
            ids=["FL","FR","RL","RR"];
            for k=1:4, t.verifyEqual(r.nativePayload.system.tires{k},fsd.tire.verticalModel(t.Tire,ids(k))); end
        end
        function forceOnlyRevisionKeepsVerticalDependencies(t)
            d=t.Tire.definition; d.force.parameters.mu0=1.2;
            [p,new]=fsd.project.registerTire(t.Project,d); p=fsd.project.assignTires(p,assignments(new));
            report=fsd.project.resultCompatibility(t.Global,p);
            t.verifyEqual(report.status,"REUSABLE_DEPENDENCIES");
            t.verifyEqual(p.definition.results,t.Project.definition.results);
            t.verifyEqual(fsd.project.findTire(p,d.id,1),t.Tire);
        end
        function verticalChangesStale(t)
            for n=["RADIUS","STIFFNESS","SOURCE"]
                d=t.Tire.definition;
                switch n
                    case "RADIUS", d.geometry.unloadedRadius_m=.251;
                    case "STIFFNESS", d.vertical.stiffness_N_per_m=110000;
                    case "SOURCE", d.provenance.stiffness_N_per_m.sourceNote="New explicit source";
                end
                [p,new]=fsd.project.registerTire(t.Project,d); p=fsd.project.assignTires(p,assignments(new));
                t.verifyEqual(fsd.project.resultCompatibility(t.Global,p).status,"STALE",n);
            end
        end
        function libraryRevisionsCannotBeOverwrittenOrRemoved(t)
            resources=t.Project.definition.resources; resources.tires{1}.definition.force.parameters.mu0=1.1;
            resources.tires{1}=fsd.tire.create(resources.tires{1}.definition);
            t.verifyError(@()fsd.project.reviseEngineeringProject(t.Project,struct('resources',resources)),'fsd:project:InvalidInput');
            resources=t.Project.definition.resources; resources.tires={}; resources.tireAssignments={};
            t.verifyError(@()fsd.project.reviseEngineeringProject(t.Project,struct('resources',resources)),'fsd:project:InvalidInput');
        end
        function incompleteResourceCanBeStoredAndAssigned(t)
            p=t.Project; d=struct('id',"PENDING_TIRE"); [p,tire]=fsd.project.registerTire(p,d);
            p=fsd.project.assignTires(p,assignments(tire)); ready=fsd.project.designReadiness(p,t.Definition.id);
            t.verifyEqual(ready.status,"MISSING_DATA");
            t.verifyTrue(any(ready.missing=="TIRE:FR:CONFIGURE_VERTICAL_TIRE"));
            t.verifyEmpty(tire.definition.geometry.unloadedRadius_m); t.verifyEmpty(tire.definition.force.parameters.mu0);
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); f=fullfile(folder.Folder,'incomplete.mat');
            fsd.project.saveEngineeringProject(p,f,false); t.verifyEqual(fsd.project.loadEngineeringProject(f),p);
        end
        function studyExecutionExactMatAndSemanticTamper(t)
            [~,s,q]=tireCharacterizationInputs; p=t.Project;
            d=study(t.Tire,s,q); p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
            [r,p]=fsd.project.runEngineeringScenario(p,d.id,'TIRE_CURVE');
            t.verifyEqual(r.nativePayload.states.alpha_rad,s.alpha_rad);
            t.verifyEqual(r.nativePayload.Fy_N(61),0);
            forged=r; forged.nativePayload.Fy_N(1)=0;
            t.verifyError(@()fsd.project.validateEngineeringResult(forged),'fsd:project:InvalidEngineeringResult');
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); file=fullfile(folder.Folder,'tires.mat');
            fsd.project.saveEngineeringProject(p,file,false); t.verifyEqual(fsd.project.loadEngineeringProject(file),p);
        end
        function ambiguousGlobalSourceRejected(t)
            d=t.Definition; d.inputs.tires=t.Global.nativePayload.system.tires;
            p=fsdui.upsertScenario(t.Project,fsd.project.createEngineeringScenario(d));
            t.verifyEqual(fsd.project.designReadiness(p,d.id).status,"INVALID_INPUT");
        end
        function missingAssignmentAndLegacySourceRemainDistinct(t)
            p=fsd.project.assignTires(t.Project,{}); ready=fsd.project.designReadiness(p,t.Definition.id);
            t.verifyTrue(any(ready.missing=="TIRE:FR:ASSIGN_LIBRARY_REVISION"));
            d=t.Definition; d.inputs=struct('tires',{t.Global.nativePayload.system.tires});
            p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(d));
            t.verifyEqual(fsd.project.designReadiness(p,d.id).status,"READY");
        end
        function tableRoundTripKeepsExplicitData(t)
            rows=fsdui.tireConfiguration('ROWS',t.Tire); d=t.Tire.definition;
            rows.id=d.id; rows.name=d.name; rows.level=d.level; rows.evidence=d.evidence; rows.note=d.note; rows.family=d.force.family;
            converted=fsdui.tireConfiguration('DEFINITION',rows,t.Tire);
            t.verifyEqual(fsd.tire.create(converted),t.Tire);
        end
    end
end
function a=assignments(tire)
ids=["FL","FR","RL","RR"]; a=cell(4,1);
for k=1:4, a{k}=struct('cornerId',ids(k),'tireId',tire.definition.id,'tireRevision',tire.definition.revision); end
end
function d=study(tire,states,request)
d=struct('id',"TIRE_STUDY",'engine',"TIRE_CHARACTERIZATION",'scope',fsd.model.designScope('VEHICLE','VEHICLE'), ...
    'inputs',struct('tireId',tire.definition.id,'tireRevision',tire.definition.revision), ...
    'plan',struct('states',states,'request',request));
end
