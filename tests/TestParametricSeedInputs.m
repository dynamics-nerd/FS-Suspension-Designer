classdef TestParametricSeedInputs < matlab.unittest.TestCase
    properties (TestParameter)
        Missing={"WHEEL_EFFECTIVE_RADIUS","NOMINAL_TOE","NOMINAL_CAMBER","UPRIGHT_CLOCKING", ...
            "UBJ_X","UBJ_OUTBOARD","UBJ_Z","LBJ_X","LBJ_OUTBOARD","LBJ_Z", ...
            "TIE_OUT_X","TIE_OUT_OUTBOARD","TIE_OUT_Z", ...
            "UCA_CENTER_X","UCA_LATERAL","UCA_HEIGHT","UCA_SPAN","UCA_LATERAL_DELTA","UCA_HEIGHT_DELTA", ...
            "LCA_CENTER_X","LCA_LATERAL","LCA_HEIGHT","LCA_SPAN","LCA_LATERAL_DELTA","LCA_HEIGHT_DELTA", ...
            "TIE_IN_X","TIE_IN_LATERAL","TIE_IN_HEIGHT"}
        Role={"KNOWN","FIXED","ASSUMED","DERIVED","RULE","TARGET","RANGE","FREE"}
        Quantity={"WHEELBASE","FRONT_TRACK"}
        BadNumber={NaN,Inf,1i}
    end
    methods (TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples'));
        end
    end
    methods (Test)
        function eachDecisionMissingIsIdentified(t,Missing)
            f=parametricSeedFixture(); d=f.definition.definitionSI;
            d.parameters=d.parameters(~cellfun(@(p)p.definitionSI.id==Missing,d.parameters));
            definition=fsd.construction.createParametricSeedDefinition(d);
            r=fsd.construction.parametricSeedReadiness(definition,f.references);
            t.verifyEqual(r.status,"MISSING_DATA"); t.verifyTrue(any(r.missing=="FL:"+Missing));
            seed=fsd.construction.buildParametricSeed(definition,f.references);
            t.verifyEmpty(seed.geometries); t.verifyEqual(seed.sampledStatus,"NOT_CHECKED");
        end
        function semanticRolePrecedesAvailability(t,Role)
            f=parametricSeedFixture(); value=.25; if ismember(Role,["RANGE","FREE"]), value=[]; end
            definition=replaceSeedDecision(f.definition,'WHEEL_EFFECTIVE_RADIUS',value,Role);
            r=fsd.construction.parametricSeedReadiness(definition,f.references);
            usable=ismember(Role,["KNOWN","FIXED","ASSUMED","DERIVED"]);
            if usable, t.verifyEqual(r.status,"READY"); else, t.verifyEqual(r.status,"MISSING_DATA"); end
            if Role=="RULE", t.verifyTrue(any(contains(r.diagnostics,"RULE_IS_NOT_A_PHYSICAL_INPUT"))); end
            if Role=="TARGET", t.verifyTrue(any(contains(r.diagnostics,"TARGET_IS_NOT_A_FACT"))); end
        end
        function physicalConceptRoleGate(t,Quantity,Role)
            f=parametricSeedFixture(); cd=f.concept.definitionSI; i=cellfun(@(p)p.id==Quantity,cd.parameters);
            input=struct('type',Role,'value',1.3,'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Test declaration");
            if ismember(Role,["RANGE","FREE"]), input.value=[]; input.bounds=[1,2]; input.availability="NOT_PROVIDED"; end
            if ismember(Role,["KNOWN","FIXED"]), input.availability="KNOWN"; input.sourceKind="KNOWN"; end
            if Role=="DERIVED", input.availability="DERIVED"; input.sourceKind="DERIVED"; input.derivationReference="TEST"; end
            if Role=="RULE"
                input.ruleReference=struct('organizer',"TEST",'version',"TEST",'ruleId',"FICTITIOUS", ...
                    'quantity',"LENGTH",'source',"TEST",'status',"VERIFIED",'applicability',"TEST");
            end
            cd.parameters{i}=fsd.project.createConceptParameter(Quantity,input,'m');
            p=fsd.project.reviseEngineeringProject(f.project,struct('concept',fsd.project.createVehicleConcept(cd)));
            r=fsd.project.designReadiness(p,'BUILD');
            if ismember(Role,["KNOWN","FIXED","ASSUMED","DERIVED"]), t.verifyEqual(r.status,"READY");
            else, t.verifyEqual(r.status,"MISSING_DATA"); t.verifyTrue(any(r.missing=="CONCEPT:"+Quantity)); end
        end
        function explicitIntervalSelectionPreservesOriginalBounds(t)
            f=parametricSeedFixture(); definition=replaceSeedDecision(f.definition,'WHEEL_EFFECTIVE_RADIUS',[],'RANGE');
            t.verifyEqual(fsd.construction.parametricSeedReadiness(definition,f.references).status,"MISSING_DATA");
            definition=replaceSeedDecision(definition,'WHEEL_EFFECTIVE_RADIUS',.3,'RANGE');
            t.verifyEqual(fsd.construction.parametricSeedReadiness(definition,f.references).status,"READY");
            i=cellfun(@(p)p.definitionSI.id=="WHEEL_EFFECTIVE_RADIUS",definition.definitionSI.parameters);
            t.verifyEqual(definition.definitionSI.parameters{i}.definitionSI.bounds,[.1,.5]);
        end
        function nonfiniteRejectedByNativeFactory(t,BadNumber)
            t.verifyError(@()fsd.construction.createSeedParameter('UCA_HEIGHT','FL',struct('type',"ASSUMED", ...
                'value',BadNumber,'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Invalid test"),'m'), ...
                'fsd:model:InvalidDesignDefinition');
        end
        function conversionAtBoundaryAndUnknownUnit(t)
            f=parametricSeedFixture();
            f.definition=replaceSeedDecision(f.definition,'NOMINAL_TOE',.03);
            f.definition=replaceSeedDecision(f.definition,'NOMINAL_CAMBER',-.06);
            f.definition=replaceSeedDecision(f.definition,'UPRIGHT_CLOCKING',.1);
            d=f.definition.definitionSI;
            for j=1:numel(d.parameters)
                original=d.parameters{j}; q=original.definitionSI;
                input=rmfield(q,{'id','quantity','scope','binding','unit'});
                unit='mm'; multiplier=1000;
                if q.quantity=="ANGLE", unit='deg'; multiplier=180/pi; end
                input.value=input.value*multiplier; d.parameters{j}=fsd.construction.createSeedParameter(q.id,'FL',input,unit);
            end
            a=fsd.construction.buildParametricSeed(f.definition,f.references);
            b=fsd.construction.buildParametricSeed(fsd.construction.createParametricSeedDefinition(d),f.references);
            t.verifyEqual(a.geometries{1}.hardpoints.xyz_m,b.geometries{1}.hardpoints.xyz_m,'AbsTol',1e-14);
            t.verifyError(@()fsd.construction.createSeedParameter('UCA_SPAN','FL', ...
                struct('type',"KNOWN"),'inch'),'fsd:model:InvalidDesignDefinition');
        end
        function inputReadinessNeverBuildsOrSolves(t)
            f=parametricSeedFixture('FRONT'); profile clear; profile on;
            fsd.project.designReadiness(f.project,'BUILD'); fsd.project.prepareEngineeringScenario(f.project,'BUILD');
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["seedBuildCore","solveBump","fsolve","boundedDirectSearch"])));
            t.verifyEmpty(f.project.definition.resources.geometries);
        end
        function requiresDeclaredFamilyAndOppositeSide(t)
            f=parametricSeedFixture('FRONT'); d=f.definition.definitionSI; d.family="UNSELECTED";
            r=fsd.construction.parametricSeedReadiness(fsd.construction.createParametricSeedDefinition(d),f.references);
            t.verifyTrue(any(r.missing=="FAMILY"));
            d.family="INDEPENDENT_DOUBLE_WISHBONE"; d.symmetry="NONE";
            r=fsd.construction.parametricSeedReadiness(fsd.construction.createParametricSeedDefinition(d),f.references);
            t.verifyTrue(any(startsWith(r.missing,"FR:")));
            d.family="MACPHERSON"; r=fsd.construction.parametricSeedReadiness(fsd.construction.createParametricSeedDefinition(d),f.references);
            t.verifyEqual(r.status,"UNSUPPORTED");
        end
        function idsScopesAndDuplicatesAreNotAliases(t)
            f=parametricSeedFixture(); d=f.definition.definitionSI; d.parameters{end+1}=d.parameters{1};
            t.verifyError(@()fsd.construction.createParametricSeedDefinition(d),'fsd:construction:InvalidInput');
            t.verifyError(@()fsd.construction.createSeedParameter('FAKE','FL',struct('type',"KNOWN"),'m'), ...
                'fsd:construction:InvalidInput');
        end
    end
end
