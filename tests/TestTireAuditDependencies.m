classdef TestTireAuditDependencies < matlab.unittest.TestCase
    methods(TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
        end
    end
    methods(Test)
        function pureLateralUnusedStiffnessReusesWithoutChangingHistory(t)
            [p,r,d]=baseline(); before=p.definition.results;
            d.force.parameters.Ckappa_N=17000; [changed,tire]=revision(p,d);
            t.verifyEqual(fsd.project.resultCompatibility(r,changed).status,"REUSABLE_DEPENDENCIES");
            t.verifyEqual(changed.definition.results,before); t.verifyEqual(r.prepared.tire.definition.revision,1);
            t.verifyNotEqual(tire.identity,r.prepared.tire.identity);
            s=r.nativePayload.states;
            % Independent unsaturated lateral oracle, not two solver arrays.
            t.verifyEqual(r.nativePayload.Fy_N,-8000*tan(s.alpha_rad),'AbsTol',1e-10);
            current=fsd.tire.evaluate(tire,s,struct('channels',"Fy"));
            t.verifyEqual(current.Fy_N,-8000*tan(s.alpha_rad),'AbsTol',1e-10);
            t.verifyEqual(changed.definition.results{1}.identity,r.identity);
        end
        function consumedLateralAndCamberParametersAndSourcesStale(t)
            [p,r,d]=baseline(.02);
            for key=["Calpha_N_per_rad","Cgamma_N_per_rad","qGamma_per_rad2"]
                changed=d; changed.force.parameters.(key)=changed.force.parameters.(key)*1.1;
                pp=revision(p,changed); t.verifyEqual(fsd.project.resultCompatibility(r,pp).status,"STALE",key);
            end
            d.provenance.Calpha_N_per_rad.sourceNote="Changed consumed source";
            pp=revision(p,d); t.verifyEqual(fsd.project.resultCompatibility(r,pp).status,"STALE");
        end
        function combinedAndLongitudinalRequestsConsumeCkappa(t)
            for mode=["COMBINED","FX_REQUESTED"]
                [p,~,d]=baseline(); sd=p.definition.scenarios{1}.definition;
                if mode=="COMBINED", sd.plan.states.kappa=.05; else, sd.plan.request.channels=["Fy";"Fx"]; end
                p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(sd));
                [r,p]=fsd.project.runEngineeringScenario(p,sd.id,"CONSUMED_RESULT");
                d.force.parameters.Ckappa_N=12000; pp=revision(p,d);
                t.verifyEqual(fsd.project.resultCompatibility(r,pp).status,"STALE",mode);
            end
        end
        function statesChannelsAndConsumedLawsStale(t)
            [p,r,d]=baseline(.02);
            for mode=["STATES","CHANNELS","POLICY","CAMBER_THRUST","CAMBER_CAPACITY","LOAD_LAW"]
                pp=p; sd=pp.definition.scenarios{1}.definition; dd=d;
                switch mode
                    case "STATES", sd.plan.states.alpha_rad=[-.02;0;.02];
                    case "CHANNELS", sd.plan.request.channels=["Fy";"Fx"];
                    case "POLICY", sd.plan.request.domainPolicy="REJECT";
                    case "CAMBER_THRUST", dd.force.camberThrust="NEGLECTED";
                    case "CAMBER_CAPACITY", dd.force.camberCapacity="NEGLECTED";
                    case "LOAD_LAW", dd.force.lateralLoad="CONSTANT";
                end
                if startsWith(mode,"CAMBER")||mode=="LOAD_LAW", pp=revision(pp,dd);
                else, pp=fsdui.upsertScenario(pp,fsd.project.createEngineeringScenario(sd)); end
                t.verifyEqual(fsd.project.resultCompatibility(r,pp).status,"STALE",mode);
            end
        end
        function independentResourceAndUnconsumedGeometryKeepEvidence(t)
            [p,r,d]=baseline(); dd=d; dd.id="INDEPENDENT_TIRE"; [pp,~]=fsd.project.registerTire(p,dd);
            t.verifyEqual(fsd.project.resultCompatibility(r,pp).status,"REUSABLE_DEPENDENCIES");
            d.geometry.width_m=.2; pp=revision(p,d);
            t.verifyEqual(fsd.project.resultCompatibility(r,pp).status,"REUSABLE_DEPENDENCIES");
            t.verifyEqual(pp.definition.results,p.definition.results);
        end
        function defaultRequestsAndScalarExpansionHaveSameDependencies(t)
            [p,~,~]=baseline(); sd=p.definition.scenarios{1}.definition;
            sd.plan.request=struct(); p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(sd));
            [r,p]=fsd.project.runEngineeringScenario(p,sd.id,"DEFAULT_RESULT");
            sd.plan.request=struct('channels',["Fx";"Fy"],'domainPolicy',"MARK");
            sd.plan.states.Fz_N=500*ones(3,1);
            pp=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(sd));
            t.verifyEqual(fsd.project.resultCompatibility(r,pp).status,"REUSABLE_DEPENDENCIES");
            sd.plan.request.channels=["Fy";"Fx"];
            pp=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(sd));
            t.verifyEqual(fsd.project.resultCompatibility(r,pp).status,"STALE");
        end
        function reuseAndCompleteExecutionContextRoundTripExactly(t)
            [p,r,d]=baseline(); d.force.parameters.Ckappa_N=12000; pp=revision(p,d);
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); file=fullfile(folder.Folder,'reuse.mat');
            fsd.project.saveEngineeringProject(pp,file,false); restored=fsd.project.loadEngineeringProject(file);
            t.verifyEqual(restored,pp); t.verifyEqual(restored.definition.results{1},r);
            t.verifyEqual(r.prepared.context.tire,r.prepared.tire.identity);
            t.verifyEqual(fsd.project.resultCompatibility(r,restored).status,"REUSABLE_DEPENDENCIES");
        end
        function projectionDoesNotCompareComputedForces(t)
            [d,s,q]=tireCharacterizationInputs; q.channels="Fy"; s.alpha_rad=[-.01;0;.01];
            a=fsd.tire.evaluationDependencies(fsd.tire.create(d),s,q);
            t.verifyFalse(isfield(a.force.parameters,'Ckappa_N')); t.verifyFalse(isfield(a.force,'longitudinalLoad'));
            t.verifyFalse(isfield(a,'Fx_N')); t.verifyFalse(isfield(a,'Fy_N'));
            s.kappa=.01; b=fsd.tire.evaluationDependencies(fsd.tire.create(d),s,q);
            t.verifyTrue(isfield(b.force.parameters,'Ckappa_N'));
            t.verifyTrue(isfield(b.force.parameters,'pKappa'));
        end
    end
end
function [p,r,d]=baseline(gamma)
if nargin<1, gamma=0; end
[d,s,~]=tireCharacterizationInputs; s.alpha_rad=[-.01;0;.01]; s.gamma_rad=gamma;
p=fsd.project.createEngineeringProject(struct('concept',fsd.project.createVehicleConcept(struct('id',"DEPENDENCY_FIX"))));
[p,tire]=fsd.project.registerTire(p,d);
scenario=fsd.project.createEngineeringScenario(struct('id',"LATERAL",'engine',"TIRE_CHARACTERIZATION", ...
    'scope',fsd.model.designScope('VEHICLE','VEHICLE'),'inputs',struct('tireId',tire.definition.id,'tireRevision',1), ...
    'plan',struct('states',s,'request',struct('channels',"Fy"))));
p=fsdui.upsertScenario(p,scenario); [r,p]=fsd.project.runEngineeringScenario(p,'LATERAL','ORIGINAL_RESULT');
end
function [p,tire]=revision(p,d)
[p,tire]=fsd.project.registerTire(p,d); sd=p.definition.scenarios{1}.definition;
sd.inputs.tireRevision=tire.definition.revision;
p=fsdui.upsertScenario(p,fsd.project.createEngineeringScenario(sd));
end
