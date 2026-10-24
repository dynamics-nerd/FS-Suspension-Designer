classdef TestTireAuditNumeric < matlab.unittest.TestCase
    properties(TestParameter)
        Coefficient={"Calpha_N_per_rad","Ckappa_N","Fz0_N"}
    end
    methods(TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
        end
    end
    methods(Test)
        function integerCoefficientsAreCanonicalAndEquivalent(t,Coefficient)
            [d,s,q]=tireCharacterizationInputs; reference=fsd.tire.create(d);
            d.force.parameters.(Coefficient)=int32(d.force.parameters.(Coefficient));
            tire=fsd.tire.create(d); t.verifyClass(tire.definition.force.parameters.(Coefficient),'double');
            t.verifyTrue(fsd.tire.validate(tire)); t.verifyEqual(tire,reference);
            t.verifyEqual(fsd.tire.readiness(tire,s,q).status,"READY");
            t.verifyEqual(fsd.tire.evaluate(tire,s,q),fsd.tire.evaluate(reference,s,q));
        end
        function integerExponentsGeometryAndDomainsAreCanonical(t)
            [d,s,q]=tireCharacterizationInputs;
            for key=["n","pAlpha","pKappa"], d.force.parameters.(key)=int32(1); end
            d.force.parameters.qGamma_per_rad2=uint16(1); d.revision=uint8(1);
            d.vertical.stiffness_N_per_m=int32(100000); d.force.domain.Fz_N=uint16([0,2000]);
            d.geometry.width_m=single(.18);
            tire=fsd.tire.create(d); ref=d;
            for key=["n","pAlpha","pKappa","qGamma_per_rad2"], ref.force.parameters.(key)=double(ref.force.parameters.(key)); end
            ref.revision=1; ref.vertical.stiffness_N_per_m=100000; ref.force.domain.Fz_N=[0,2000];
            t.verifyClass(tire.definition.geometry.width_m,'double');
            t.verifyEqual(tire.definition.geometry.width_m,double(single(.18)));
            t.verifyEqual(tire,fsd.tire.create(ref)); t.verifyTrue(fsd.tire.validate(tire));
            s.Fz_N=[250;500;1000]; s.alpha_rad=.02; s.kappa=.03; s.gamma_rad=.01;
            t.verifyEqual(fsd.tire.readiness(tire,s,q).status,"READY");
            t.verifyEqual(fsd.tire.evaluate(tire,s,q),fsd.tire.evaluate(fsd.tire.create(ref),s,q));
        end
        function unsafeOrUnsupportedNumericDeclarationsAreRejected(t)
            invalid={complex(8000,1),[8000,8000],NaN,Inf,true,"8000", ...
                uint64(flintmax)+uint64(1),intmax('int64'),intmin('int64')};
            for k=1:numel(invalid)
                d=tireCharacterizationInputs; d.force.parameters.Calpha_N_per_rad=invalid{k};
                t.verifyError(@()fsd.tire.create(d),'fsd:tire:InvalidDefinition',sprintf('case%d',k));
            end
            d=tireCharacterizationInputs; d.force.parameters.Calpha_N_per_rad=uint64(flintmax);
            tire=fsd.tire.create(d); t.verifyClass(tire.definition.force.parameters.Calpha_N_per_rad,'double');
        end
        function validatorRejectsUnnormalizedNumericIdentity(t)
            tire=fsd.tire.create(tireCharacterizationInputs);
            tire.definition.force.parameters.Calpha_N_per_rad=int32(8000);
            tire.identity.force.parameters.Calpha_N_per_rad=int32(8000);
            t.verifyError(@()fsd.tire.validate(tire),'fsd:tire:InvalidDefinition');
            tire=fsd.tire.create(tireCharacterizationInputs); tire.identity.force.parameters.mu0=true;
            t.verifyError(@()fsd.tire.validate(tire),'fsd:tire:InvalidDefinition');
        end
        function canonicalIntegersSurviveProjectRunAndMat(t)
            [d,s,q]=tireCharacterizationInputs; d.force.parameters.Calpha_N_per_rad=int32(8000);
            d.force.parameters.Ckappa_N=int32(10000); d.force.parameters.Fz0_N=int32(500);
            p=fsd.project.createEngineeringProject(struct('concept',fsd.project.createVehicleConcept(struct('id',"NUMERIC_FIX"))));
            [p,tire]=fsd.project.registerTire(p,d);
            scenario=fsd.project.createEngineeringScenario(struct('id',"INTEGER_STUDY",'engine',"TIRE_CHARACTERIZATION", ...
                'scope',fsd.model.designScope('VEHICLE','VEHICLE'),'inputs',struct('tireId',tire.definition.id,'tireRevision',1), ...
                'plan',struct('states',s,'request',q)));
            p=fsdui.upsertScenario(p,scenario); [r,p]=fsd.project.runEngineeringScenario(p,'INTEGER_STUDY','INTEGER_RESULT');
            t.verifyClass(r.prepared.tire.definition.force.parameters.Fz0_N,'double');
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); file=fullfile(folder.Folder,'integers.mat');
            fsd.project.saveEngineeringProject(p,file,false); restored=fsd.project.loadEngineeringProject(file);
            t.verifyEqual(restored,p); t.verifyClass(restored.definition.resources.tires{1}.definition.force.parameters.Calpha_N_per_rad,'double');
        end
    end
end
