classdef TestSynthesisSpace < matlab.unittest.TestCase
    % SI binding/immutability tests; tolerances are floating-point only.
    properties (TestParameter)
        Axis={1,2,3}
        BadVector={NaN,Inf,-.1,1.1}
        Span={1e-12,1e-6,1,1e6}
        BadPlan={struct('travel_m',[0;0]),struct('travel_m',[0;.01;-.01]),struct('travel_m',NaN),struct('travel_m',0,'extra',1)}
    end
    methods (TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@() path(old)); root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'src'));
        end
    end
    methods (Test)
        function coordinateOnly(t,Axis)
            s=synthesisFixture(Axis); seed=s.seed; x=s.initial_m+.005;
            [g,changes]=fsd.synthesis.buildCandidateGeometry(s,x);
            expected=seed.hardpoints.xyz_m; expected(1,Axis)=x;
            t.verifyEqual(g.hardpoints.xyz_m,expected); t.verifyEqual(s.seed,seed);
            t.verifyNotEqual(fsd.model.geometryIdentity(g),s.seedIdentity);
            t.verifyNumElements(changes,1); t.verifyEqual(g.hardpoints.sourceKind(1,Axis),"DERIVED");
            t.verifyTrue(fsd.model.validateDoubleWishboneGeometry(g));
        end
        function twoVariables(t)
            s=synthesisFixture([1,3]); g=fsd.synthesis.buildCandidateGeometry(s,s.upper_m);
            t.verifyEqual(g.hardpoints.xyz_m(1,1),s.upper_m(1)); t.verifyEqual(g.hardpoints.xyz_m(2,3),s.upper_m(2));
            t.verifyEqual(g.hardpoints.xyz_m(3:end,:),s.seed.hardpoints.xyz_m(3:end,:));
        end
        function seedRoundTripExact(t)
            s=synthesisFixture(); u=fsd.synthesis.normalizeVariables(s,s.initial_m);
            t.verifyEqual(fsd.synthesis.denormalizeVariables(s,u),s.initial_m);
            g=fsd.synthesis.buildCandidateGeometry(s,s.initial_m); t.verifyEqual(g,s.seed);
        end
        function unselectedWheelAxisIsBitExact(t)
            s=synthesisFixture(3); seed=s.seed;
            % A valid near-unit input within the historical software tolerance.
            seed.wheel.wheelAxis=seed.wheel.wheelAxis*(1+1e-10);
            t.assertTrue(fsd.model.validateDoubleWishboneGeometry(seed));
            s=fsd.synthesis.createDesignSpace(seed,s.specification,s.plan);
            g=fsd.synthesis.buildCandidateGeometry(s,s.upper_m);
            t.verifyEqual(g.wheel,seed.wheel);
            unchanged=fsd.synthesis.buildCandidateGeometry(s,s.initial_m);
            t.verifyEqual(fsd.model.geometryIdentity(unchanged),s.seedIdentity);
        end
        function roundTripScale(t,Span)
            s=synthesisFixture(1); d=s.specification.definitionSI.parameters{1}.definitionSI;
            d.bounds=d.value+[-Span,Span]; s=reparameter(s,d);
            u=.731; x=fsd.synthesis.denormalizeVariables(s,u);
            tolerance=8*eps(max(abs(d.bounds)))/(d.bounds(2)-d.bounds(1));
            t.verifyEqual(fsd.synthesis.normalizeVariables(s,x),u,'AbsTol',tolerance);
            t.verifyEqual(fsd.synthesis.denormalizeVariables(s,0),s.lower_m);
            t.verifyEqual(fsd.synthesis.denormalizeVariables(s,1),s.upper_m);
        end
        function differentScales(t)
            s=synthesisFixture(); p=s.specification.definitionSI.parameters;
            d=p{1}.definitionSI; d.bounds=d.value+[-1e-10,1e-10]; p{1}=fsd.model.createDesignParameter(d,'m');
            d=p{2}.definitionSI; d.bounds=[-1e6,1e6]; p{2}=fsd.model.createDesignParameter(d,'m');
            s=replaceParameters(s,p); u=[.123;.789]; x=fsd.synthesis.denormalizeVariables(s,u);
            t.verifyEqual(fsd.synthesis.normalizeVariables(s,x),u,'AbsTol',1e-6); % roundoff of narrow span around .36m
        end
        function frozenInterval(t)
            s=synthesisFixture(3); d=s.specification.definitionSI.parameters{1}.definitionSI; d.bounds=[d.value,d.value]; s=reparameter(s,d);
            t.verifyFalse(s.active); t.verifyEqual(fsd.synthesis.normalizeVariables(s,d.value),0);
            t.verifyError(@() fsd.synthesis.denormalizeVariables(s,1),'fsd:synthesis:InvalidInput');
        end
        function invalidNormalized(t,BadVector)
            s=synthesisFixture(3); t.verifyError(@() fsd.synthesis.denormalizeVariables(s,BadVector),'fsd:synthesis:InvalidInput');
        end
        function incorrectDimensions(t)
            s=synthesisFixture(); t.verifyError(@() fsd.synthesis.denormalizeVariables(s,[0;0;0]),'fsd:synthesis:InvalidInput');
        end
        function invalidPlan(t,BadPlan)
            s=synthesisFixture(); t.verifyError(@() fsd.synthesis.createDesignSpace(s.seed,s.specification,BadPlan),'fsd:synthesis:InvalidInput');
        end
        function reversedBounds(t)
            s=synthesisFixture(3); d=s.specification.definitionSI.parameters{1}.definitionSI; d.bounds=fliplr(d.bounds);
            t.verifyError(@() fsd.model.createDesignParameter(d,'m'),'fsd:model:InvalidDesignDefinition');
        end
        function unknownHardpoint(t)
            t.verifyError(@() fsd.model.designScope('HARDPOINT','FL_MISSING','FL'),'fsd:model:InvalidDesignDefinition');
        end
        function wrongCorner(t)
            s=synthesisFixture(3); d=s.specification.definitionSI.parameters{1}.definitionSI;
            d.scope=fsd.model.designScope('HARDPOINT','FR_UCA_FWD_CHASSIS','FR');
            t.verifyError(@() reparameter(s,d),'fsd:synthesis:InvalidInput');
        end
        function unsupportedOutboard(t)
            s=synthesisFixture(3); d=s.specification.definitionSI.parameters{1}.definitionSI;
            d.scope=fsd.model.designScope('HARDPOINT','FL_UBJ','FL'); d.value=.420; d.bounds=[.41,.43];
            t.verifyError(@() reparameter(s,d),'fsd:synthesis:InvalidInput');
        end
        function wrongQuantity(t)
            s=synthesisFixture(3); d=s.specification.definitionSI.parameters{1}.definitionSI;
            t.verifyError(@() fsd.model.createDesignParameter(d,'rad'),'fsd:model:InvalidDesignDefinition');
        end
        function mismatchedInitial(t)
            s=synthesisFixture(3); d=s.specification.definitionSI.parameters{1}.definitionSI; d.value=d.value+.001;
            t.verifyError(@() reparameter(s,d),'fsd:synthesis:InvalidInput');
        end
        function duplicateBinding(t)
            s=synthesisFixture(3); p=s.specification.definitionSI.parameters{1}; d=p.definitionSI; d.id="SECOND";
            t.verifyError(@() replaceParameters(s,{p;fsd.model.createDesignParameter(d,'m')}),'fsd:synthesis:InvalidInput');
        end
        function fixedCannotBeMoved(t)
            s=synthesisFixture(3); p=s.specification.definitionSI.parameters{1}; d=p.definitionSI;
            d.id="FIXED_Z"; d.type="FIXED"; d.bounds=[]; d.comparisonTolerance=0;
            t.verifyError(@() replaceParameters(s,{p;fsd.model.createDesignParameter(d,'m')}),'fsd:synthesis:InvalidInput');
        end
        function boxBoundary(t)
            s=synthesisFixture(3); d=s.specification.definitionSI; p=s.seed.hardpoints.xyz_m(1,:);
            c=fsd.model.createDesignConstraint(struct('id',"BOX",'type',"AXIS_ALIGNED_BOX",'strength',"HARD", ...
                'scope',fsd.model.designScope('HARDPOINT','FL_UCA_FWD_CHASSIS','FL'), ...
                'bounds',[p'-[0;0;.01],p'+[0;0;.01]],'sourceNote',"Test closed box only"),'m');
            d.constraints{end+1,1}=c; spec=fsd.model.createDesignSpecification(d);
            s=fsd.synthesis.createDesignSpace(s.seed,spec,s.plan);
            e=fsd.synthesis.evaluateSynthesisCandidate(s,1); t.verifyEqual(e.assessment.constraintAssessments{2}.status,"SAMPLED_PASS");
        end
        function corruptSpace(t)
            s=synthesisFixture(); s.variables{1}.column=2;
            t.verifyError(@() fsd.synthesis.validateDesignSpace(s),'fsd:synthesis:InvalidDesignSpace');
        end
    end
end

function space = reparameter(space,definition)
space=replaceParameters(space,{fsd.model.createDesignParameter(definition,'m')});
end
function space = replaceParameters(space,parameters)
d=space.specification.definitionSI; d.parameters=parameters;
space=fsd.synthesis.createDesignSpace(space.seed,fsd.model.createDesignSpecification(d),space.plan);
end
