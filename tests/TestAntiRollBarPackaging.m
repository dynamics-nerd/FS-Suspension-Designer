classdef TestAntiRollBarPackaging < matlab.unittest.TestCase
    methods(TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples'));
        end
    end
    methods(Test)
        function nominalDistanceHasIndependentSegmentSphereOracle(t)
            b=fsd.model.createAntiRollBar(antiRollBarInputs('COAXIAL_TORSION')); definition=fixture(b,[1,0,0]);
            result=fsd.packaging.evaluateAntiRollBar(definition,b);
            t.verifyEqual(result.status,"CLEAR_SAMPLED"); t.verifyEqual(result.checks{1}.distance_m,.89,'AbsTol',1e-12);
            t.verifyEqual(result.coverage,struct('required',1,'evaluated',1));
        end
        function collisionAndUnknownDimensionsAreDifferent(t)
            b=fsd.model.createAntiRollBar(antiRollBarInputs('COAXIAL_TORSION')); definition=fixture(b,[.005,0,0]);
            t.verifyEqual(fsd.packaging.evaluateAntiRollBar(definition,b).status,"COLLISION_DETECTED");
            d=definition.definition; d.components{1}.radius_m=[]; incomplete=fsd.packaging.createAntiRollBarDefinition(d);
            t.verifyEqual(fsd.packaging.evaluateAntiRollBar(incomplete,b).status,"INCOMPLETE");
            d=definition.definition; d.pairs{1}.requiredClearance_m=[];
            t.verifyEqual(fsd.packaging.evaluateAntiRollBar(fsd.packaging.createAntiRollBarDefinition(d),b).status,"INCOMPLETE");
        end
        function unknownPointOrFrameDoesNotCertifyClearance(t)
            b=fsd.model.createAntiRollBar(antiRollBarInputs('COAXIAL_TORSION')); definition=fixture(b,[1,0,0]);
            d=definition.definition; d.components{1}.firstPoint="ARB_UNKNOWN";
            t.verifyEqual(fsd.packaging.evaluateAntiRollBar(fsd.packaging.createAntiRollBarDefinition(d),b).status,"INCOMPLETE");
            d=definition.definition; d.frame.originDescription="Different physical origin";
            t.verifyError(@()fsd.packaging.evaluateAntiRollBar(fsd.packaging.createAntiRollBarDefinition(d),b),'fsd:packaging:InvalidAntiRollBar');
        end
        function equivalentDoesNotFabricateGeometry(t)
            geometric=fsd.model.createAntiRollBar(antiRollBarInputs('COAXIAL_TORSION'));
            eq=fsd.model.createAntiRollBar(antiRollBarInputs); result=fsd.packaging.evaluateAntiRollBar(fixture(geometric,[1,0,0]),eq);
            t.verifyEqual(result.status,"NOT_SUPPORTED"); t.verifyEmpty(result.checks);
        end
        function sampledChecksRetainSourceAndUnavailableRegions(t)
            d=antiRollBarInputs('COAXIAL_TORSION'); b=fsd.model.createAntiRollBar(d); z=(-.03:.001:.03)'; sources=cell(2,1);
            for side=1:2
                sources{side}=struct('kind',"PrescribedArbDriverPath",'wheelTravel_m',z, ...
                    'points_m',d.parameters.driverPoints_m(side,:)+z*[0,0,1], ...
                    'sourceKind',"ASSUMED",'sourceNote',"Synthetic independent packaging path");
            end
            p=fsd.analysis.prepareAntiRollBar(b,sources); s=fsd.analysis.analyzeAntiRollBarKinematicSweep(p,[0,0;.06,0]);
            result=fsd.packaging.evaluateAntiRollBar(fixture(b,[1,0,0]),s);
            t.verifyEqual(result.status,"INCOMPLETE"); t.verifyNumElements(result.checks,2);
            t.verifyEqual(result.checks{1}.status,"CLEAR_SAMPLED"); t.verifyEqual(result.checks{2}.status,"INCOMPLETE");
            t.verifyEqual(result.source,s); t.verifyEqual(result.coverage,struct('required',2,'evaluated',1));
        end
    end
end
function definition=fixture(bar,center)
frame=bar.definition.referenceFrame;
c=struct('id',"SHAFT",'firstPoint',"ARB_AXIS_LEFT",'secondPoint',"ARB_AXIS_RIGHT", ...
    'radius_m',.01,'shape',"CAPSULE",'source',"Independent synthetic simplified occupied shaft");
T=eye(4); T(1:3,4)=center';
v=fsd.packaging.createVolume(struct('id',"OBSTACLE",'componentId',"OBSTACLE",'componentType',"OBSTACLE", ...
    'role',"OCCUPIED",'frame',frame,'shape',"SPHERE",'dimensions',.1,'transform',T, ...
    'binding',struct('mode',"FIXED",'cornerId',"",'pointIds',strings(0,1)), ...
    'source',"ASSUMED",'fidelity',"SYNTHETIC",'sourceRevision',1,'provenance',"Independent sphere oracle"),'m');
pair=struct('id',"CHECK",'first',"SHAFT",'second',"OBSTACLE",'requiredClearance_m',.02);
definition=fsd.packaging.createAntiRollBarDefinition(struct('id',"ARB_PACKING",'frame',frame, ...
    'components',{{c}},'obstacles',{{v}},'pairs',{{pair}},'provenance',"Explicit synthetic test, not FS data"));
end
