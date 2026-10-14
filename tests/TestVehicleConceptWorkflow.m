classdef TestVehicleConceptWorkflow < matlab.unittest.TestCase
    properties (TestParameter)
        Missing={"VEHICLE_MASS","DRIVER_MASS","WHEELBASE","CG_X","CG_Y","CG_Z"}
        Invalid={"NAN","INF","NEGATIVE","UNIT","ID","BOUNDS","VERIFIED_ASSUMED","CONTRADICT_STATE"}
        Attack={"VALUE","UNIT","ORIGIN","STATE","IDENTITY","MASS_CONVENTION","ARCHITECTURE"}
        Availability={"NOT_APPLICABLE","DERIVABLE","UNSUPPORTED","INVALID_INPUT","PENDING_CONFIRMATION"}
    end
    methods (TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples'));
        end
    end
    methods (Test)
        function partialIsNotPhysicalVehicle(t)
            c=fsd.project.createVehicleConcept(struct('id',"EMPTY"));
            t.verifyTrue(fsd.project.validateVehicleConcept(c)); d=fsd.project.deriveVehicleConcept(c);
            t.verifyEmpty(d.vehicle); t.verifyEmpty(d.values{1}.value); t.verifyEqual(d.status,"MISSING_DATA");
            p=fsd.project.createEngineeringProject(struct('concept',c)); r=fsd.project.designReadiness(p);
            t.verifyEqual(numel(r),12); t.verifyTrue(any(r{2}.missing=="GEOMETRY:FL"));
        end
        function nativeLoadsAndIndependentKnownCase(t)
            [c,o]=conceptWorkflowFixture(); d=fsd.project.deriveVehicleConcept(c,o);
            t.verifyEqual(d.vehicle.totalMass_kg,270); t.verifyEqual(d.loads.frontAxleLoad_N,1350,'AbsTol',1e-10);
            t.verifyEqual(d.loads.cornerLoads_N,675*ones(4,1),'AbsTol',1e-10);
            native=fsd.analysis.analyzeStaticVehicleLoads(d.vehicle,d.loadCase);
            t.verifyEqual(native.cornerLoads_N,d.loads.cornerLoads_N); t.verifyTrue(fsd.project.validateConceptDerivation(d,c));
        end
        function missingDataDoesNotInvent(t,Missing)
            [c,o]=conceptWorkflowFixture(); input=c.definitionSI;
            input.parameters=input.parameters(~cellfun(@(p)p.id==Missing,input.parameters));
            c=fsd.project.createVehicleConcept(input); d=fsd.project.deriveVehicleConcept(c,o);
            t.verifyTrue(fsd.project.validateConceptDerivation(d));
            if ismember(Missing,["VEHICLE_MASS","DRIVER_MASS","WHEELBASE"]), t.verifyEmpty(d.vehicle);
            else
                axis=find(["CG_X","CG_Y","CG_Z"]==Missing); t.verifyTrue(isnan(d.vehicle.cg_m(axis)));
                if Missing=="CG_X", t.verifyTrue(isnan(d.loads.frontAxleLoad_N)); end
            end
        end
        function driverAlreadyIncludedAndNoSilentDefault(t)
            [c,~]=conceptWorkflowFixture(); d=c.definitionSI; d.massConvention="INCLUDES_DRIVER";
            r=fsd.project.deriveVehicleConcept(fsd.project.createVehicleConcept(d)); t.verifyEqual(r.values{1}.value,200);
            d.massConvention="UNSPECIFIED"; r=fsd.project.deriveVehicleConcept(fsd.project.createVehicleConcept(d)); t.verifyEmpty(r.values{1}.value);
            d.massConvention="EXCLUDES_DRIVER"; original=fsd.project.createVehicleConcept(d);
            t.verifyEqual(fsd.project.deriveVehicleConcept(original).values{1}.value,270);
        end
        function explicitIntervalsAndBoundaryConversion(t)
            p=fsd.project.createConceptParameter('CG_Z',struct('type',"RANGE",'bounds',[200,400], ...
                'sourceKind',"ASSUMED",'sourceNote',"User-supplied uncertainty interval", ...
                'origin',struct('actor',"TEST_ENGINEER",'date',"2026-10-14")),'mm');
            t.verifyEqual(p.parameter.definitionSI.bounds,[.2,.4]); t.verifyEqual(p.state,"AVAILABLE_RANGE");
            c=fsd.project.createVehicleConcept(struct('id',"INTERVAL",'parameters',{{p}})); original=c;
            selected=fsd.project.selectConceptValues(c,{struct('id',"CG_Z",'value',300,'unit',"mm",'sourceNote',"Explicit sample")});
            t.verifyEqual(selected.definitionSI.parameters{1}.parameter.definitionSI.value,.3);
            t.verifyEqual(selected.definitionSI.parameters{1}.parameter.definitionSI.sourceKind,"ASSUMED");
            t.verifyEqual(c,original); t.verifyNotEqual(selected.identity,c.identity);
            t.verifyError(@()fsd.project.selectConceptValues(c,{struct('id',"CG_Z",'value',500,'unit',"mm",'sourceNote',"Outside")}), ...
                'fsd:project:InvalidInput');
        end
        function invalidParameter(t,Invalid)
            d=struct('type',"ASSUMED",'value',200,'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Test"); id="VEHICLE_MASS"; unit="kg";
            switch Invalid
                case "NAN", d.value=NaN;
                case "INF", d.value=Inf;
                case "NEGATIVE", d.value=-1;
                case "UNIT", unit="mm";
                case "ID", id="GUESS";
                case "BOUNDS", d.type="RANGE"; d.bounds=[300,100];
                case "VERIFIED_ASSUMED", d.confirmation="VERIFIED"; d.origin=struct('reference',"test");
                case "CONTRADICT_STATE", d.state="UNKNOWN";
            end
            t.verifyTrue(rejects(@()fsd.project.createConceptParameter(id,d,unit)));
        end
        function manipulatedConcept(t,Attack)
            [c,~]=conceptWorkflowFixture();
            switch Attack
                case "VALUE", c.definitionSI.parameters{1}.parameter.definitionSI.value=42;
                case "UNIT", c.definitionSI.parameters{1}.parameter.definitionSI.unit="mm";
                case "ORIGIN", c.definitionSI.parameters{1}.origin.actor="OTHER";
                case "STATE", c.definitionSI.parameters{1}.state="UNKNOWN";
                case "IDENTITY", c.identity.kind="OTHER";
                case "MASS_CONVENTION", c.definitionSI.massConvention="INCLUDES_DRIVER";
                case "ARCHITECTURE", c.definitionSI.architectures.frontSuspension="OTHER";
            end
            t.verifyError(@()fsd.project.validateVehicleConcept(c),'fsd:project:InvalidVehicleConcept');
        end
        function fractionsDeriveLongitudinalCGOnly(t)
            [c,o]=conceptWorkflowFixture(); d=c.definitionSI;
            d.parameters=d.parameters(~cellfun(@(p)ismember(p.id,["CG_X","CG_Y","CG_Z"]),d.parameters));
            d.parameters{end+1}=fsd.project.createConceptParameter('FRONT_WEIGHT_FRACTION',struct('type',"ASSUMED", ...
                'value',60,'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Explicit measured-like test fraction"),'%');
            result=fsd.project.deriveVehicleConcept(fsd.project.createVehicleConcept(d),o);
            t.verifyEqual(result.vehicle.cg_m(1),.64,'AbsTol',1e-12); t.verifyTrue(all(isnan(result.vehicle.cg_m(2:3))));
        end
        function contradictoryFractionsRejectedByNativeModel(t)
            [c,o]=conceptWorkflowFixture(); d=c.definitionSI;
            d.parameters{end+1}=fsd.project.createConceptParameter('FRONT_WEIGHT_FRACTION',struct('type',"ASSUMED", ...
                'value',.7,'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Contradiction with xCG"),'1');
            r=fsd.project.deriveVehicleConcept(fsd.project.createVehicleConcept(d),o);
            t.verifyEqual(r.status,"INVALID_INPUT"); t.verifyEmpty(r.vehicle);
        end
        function staleDerivationAndTamper(t)
            [c,o]=conceptWorkflowFixture(); r=fsd.project.deriveVehicleConcept(c,o); r.values{1}.value=1;
            t.verifyError(@()fsd.project.validateConceptDerivation(r),'fsd:project:InvalidConceptDerivation');
            r=fsd.project.deriveVehicleConcept(c,o); d=c.definitionSI; d.architectures.frontSuspension="DOUBLE_WISHBONE";
            t.verifyError(@()fsd.project.validateConceptDerivation(r,fsd.project.createVehicleConcept(d)), ...
                'fsd:project:InvalidConceptDerivation');
        end
        function identityCanonicalOrderAndDuplicates(t)
            [c,~]=conceptWorkflowFixture(); d=c.definitionSI; d.parameters=flipud(d.parameters);
            t.verifyEqual(fsd.project.createVehicleConcept(d),c);
            d.parameters{end+1}=d.parameters{1}; t.verifyError(@()fsd.project.createVehicleConcept(d),'fsd:project:InvalidInput');
        end
        function statesPreserveUncertainty(t,Availability)
            d=struct('type',"KNOWN"); expected=Availability;
            switch Availability
                case "NOT_APPLICABLE", d.availability="NOT_APPLICABLE";
                case "DERIVABLE", d.type="DERIVED"; d.availability="PENDING_CALCULATION";
                case {"UNSUPPORTED","INVALID_INPUT"}, d.state=Availability; d.diagnostics="Explicit unsupported/invalid source record";
                case "PENDING_CONFIRMATION", d.confirmation="PENDING_CONFIRMATION";
            end
            p=fsd.project.createConceptParameter('CG_Z',d,'m'); t.verifyEqual(p.state,expected);
            t.verifyTrue(fsd.project.validateConceptParameter(p)); t.verifyEmpty(p.parameter.definitionSI.value);
        end
        function targetCannotBecomeVehicleFact(t)
            p=fsd.project.createConceptParameter('VEHICLE_MASS',struct('type',"TARGET",'value',200, ...
                'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Explicit goal, not vehicle fact"),'kg');
            c=fsd.project.createVehicleConcept(struct('id',"TARGET_FACT",'massConvention',"INCLUDES_DRIVER",'parameters',{{p}}));
            t.verifyEmpty(fsd.project.deriveVehicleConcept(c).values{1}.value);
        end
        function knownAndFixedAreNotSynonymsForVerified(t)
            d=struct('type',"FIXED",'value',200,'availability',"KNOWN",'sourceKind',"KNOWN", ...
                'sourceNote',"Declared user measurement");
            p=fsd.project.createConceptParameter('VEHICLE_MASS',d,'kg'); t.verifyEqual(p.confirmation,"DECLARED");
            d.confirmation="VERIFIED"; d.origin=struct('reference',"TEST_MEASUREMENT_001");
            p=fsd.project.createConceptParameter('VEHICLE_MASS',d,'kg'); t.verifyEqual(p.confirmation,"VERIFIED");
            t.verifyEqual(p.parameter.definitionSI.type,"FIXED");
        end
    end
end

function yes = rejects(callback)
yes=false;
try
    callback();
catch cause
    yes=startsWith(string(cause.identifier),'fsd:');
end
end
