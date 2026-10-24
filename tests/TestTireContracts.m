classdef TestTireContracts < matlab.unittest.TestCase
    methods(TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples'));
        end
    end
    methods(Test)
        function unknownDefinitionIsStorableButNotForceCapable(t)
            tire=fsd.tire.create(struct('id',"UNKNOWN")); s=state();
            t.verifyFalse(fsd.tire.capabilities(tire).Fx); t.verifyFalse(fsd.tire.capabilities(tire).vertical);
            r=fsd.tire.evaluate(tire,s); t.verifyTrue(all(isnan(r.Fx_N))); t.verifyEqual(r.status(1,1),"NOT_SUPPORTED");
        end
        function everyAvailableParameterNeedsSource(t)
            d=tireCharacterizationInputs; d.provenance=rmfield(d.provenance,'mu0');
            t.verifyError(@()fsd.tire.create(d),'fsd:tire:InvalidDefinition');
            d=tireCharacterizationInputs; d.provenance.mu0.sourceNote="";
            t.verifyError(@()fsd.tire.create(d),'fsd:tire:InvalidDefinition');
        end
        function shapeAndUnsupportedRequestsAreExplicit(t)
            tire=fsd.tire.create(tireCharacterizationInputs); s=state(); s.alpha_rad=[0;.1;.2]; s.kappa=[0;.1];
            t.verifyError(@()fsd.tire.evaluate(tire,s),'fsd:tire:InvalidStates');
            s=state(); s.pressure=200000;
            t.verifyError(@()fsd.tire.evaluate(tire,s),'fsd:tire:InvalidStates');
            t.verifyError(@()fsd.tire.evaluate(tire,state(),struct('channels',"Mx")),'fsd:tire:InvalidRequest');
        end
        function invalidSamplesAreMarkedWithoutTruncation(t)
            tire=fsd.tire.create(tireCharacterizationInputs); s=state();
            s.alpha_rad=[0;NaN;.5]; r=fsd.tire.evaluate(tire,s);
            t.verifySize(r.Fy_N,[3,1]); t.verifyEqual(r.status(:,2),["AVAILABLE";"INVALID_INPUT";"OUT_OF_DOMAIN"]);
            t.verifyTrue(all(isnan(r.Fy_N(2:3))));
            t.verifyError(@()fsd.tire.evaluate(tire,s,struct('domainPolicy',"REJECT")),'fsd:tire:NotReady');
        end
        function missingCamberEffectsAreNotZeroAssumptions(t)
            d=tireCharacterizationInputs; d.force.camberThrust="UNSPECIFIED"; d.force.camberCapacity="UNSPECIFIED";
            tire=fsd.tire.create(d); s=state(); s.gamma_rad=.02;
            r=fsd.tire.readiness(tire,s); t.verifyEqual(r.status,"MISSING_DATA");
            t.verifyTrue(any(contains(r.missing,'CAMBER:THRUST'))); t.verifyTrue(any(contains(r.missing,'CAMBER:CAPACITY')));
        end
        function generalContactFrameUsesActualWheelPlane(t)
            axis=[.1,.9,.3]; normal=[.2,-.1,1]; heading=[-1,.2,.1];
            frame=fsd.tire.contactFrame(heading,axis,'FR',normal); R=frame.rotationContactToGlobal;
            t.verifyEqual(dot(R(:,1),axis),0,'AbsTol',1e-14);
            t.verifyEqual(dot(R(:,1),normal),0,'AbsTol',1e-14);
            t.verifyGreaterThan(dot(R(:,1),heading),0);
            t.verifyEqual(det(R),1,'AbsTol',1e-14);
        end
        function alteredIdentityAndExecutableDataAreRejected(t)
            tire=fsd.tire.create(tireCharacterizationInputs); tire.verticalIdentity.geometryRadius_m=.4;
            t.verifyError(@()fsd.tire.validate(tire),'fsd:tire:InvalidDefinition');
            d=tireCharacterizationInputs; d.note=@sin;
            t.verifyError(@()fsd.tire.create(d),'fsd:tire:InvalidDefinition');
        end
        function qualityIsExplicitForEverySampleAndChannel(t)
            tire=fsd.tire.create(tireCharacterizationInputs); s=state(); s.Fz_N=[0;500];
            r=fsd.tire.evaluate(tire,s,struct('channels',["Fx","Mz"]));
            t.verifyEqual(r.quality(:,1),["PHYSICAL_ZERO";"ASSUMPTION_BASED"]);
            t.verifyEqual(r.quality(:,2:3),repmat("NOT_AVAILABLE",2,2));
            t.verifyEqual(r.status(:,3),repmat("NOT_SUPPORTED",2,1));
            t.verifyTrue(all(isnan(r.Mz_Nm)));
        end
    end
end
function s=state()
s=struct('Fz_N',500,'alpha_rad',0,'kappa',0,'gamma_rad',0);
end
