classdef TestRulePhysicalInput < matlab.unittest.TestCase
    % Focused audit regressions; no historical test or physical solver edits.
    properties
        PhysicalProject
        PhysicalResult
        LegacyDerivation
        LegacyResult
        LegacyProject
        IndependentProject
        IndependentResult
    end
    properties (TestParameter)
        Reference={"UNVERIFIED","VERIFIED"}
        Confirmation={"DECLARED","VERIFIED"}
        PhysicalRole={"ASSUMED","KNOWN","FIXED","DERIVED"}
        MissingRole={"TARGET","KNOWN","RANGE"}
        Quantity={"VEHICLE_MASS","DRIVER_MASS","WHEELBASE","FRONT_TRACK","REAR_TRACK", ...
            "CG_X","CG_Y","CG_Z","FRONT_WEIGHT_FRACTION","REAR_WEIGHT_FRACTION", ...
            "UNSPRUNG_MASS_FL","UNSPRUNG_MASS_FR","UNSPRUNG_MASS_RL","UNSPRUNG_MASS_RR", ...
            "WHEEL_UNLOADED_RADIUS_FRONT","WHEEL_UNLOADED_RADIUS_REAR","WHEEL_WIDTH_FRONT","WHEEL_WIDTH_REAR"}
        Revision={"RULE_VALUE","RULE_TO_ASSUMED","PHYSICAL_VALUE","RULE_REFERENCE","METADATA"}
        LegacyRoute={"DERIVATION","RESULT","PROJECT","ATTACH","COMPATIBILITY","SAVE","LOAD"}
    end
    methods (TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples'));
            t.PhysicalProject=rulePhysicalInputFixture("ASSUMED");
            t.PhysicalResult=fsd.project.runEngineeringScenario(t.PhysicalProject,'STATIC','PHYSICAL');
            [t.LegacyDerivation,t.LegacyResult,t.LegacyProject]=legacyRuleEvidence();
            d=rulePhysicalInputFixture().definition; g=actuationSynthesisSeed();
            d.resources=struct('geometries',{{g}});
            d.scenarios={fsd.project.createEngineeringScenario(struct('id',"GEOMETRY",'engine',"STATIC_GEOMETRY", ...
                'scope',fsd.model.designScope('CORNER','FL')))};
            t.IndependentProject=fsd.project.createEngineeringProject(d);
            t.IndependentResult=fsd.project.runEngineeringScenario(t.IndependentProject,'GEOMETRY','INDEPENDENT');
        end
    end
    methods (Test)
        function numericRuleCannotBecomePhysical(t,Reference,Confirmation)
            [p,c,o]=rulePhysicalInputFixture("RULE","VEHICLE_MASS",125,Reference,Confirmation); before=p;
            q=c.definitionSI.parameters{cellfun(@(x)x.id=="VEHICLE_MASS",c.definitionSI.parameters)};
            t.verifyEqual(q.state,"AVAILABLE"); t.verifyEqual(q.parameter.definitionSI.availability,"KNOWN");
            t.verifyEqual(q.parameter.definitionSI.type,"RULE"); t.verifyEqual(q.parameter.definitionSI.value,125);
            t.verifyEqual(q.parameter.definitionSI.ruleReference.status,Reference); t.verifyEqual(q.confirmation,Confirmation);
            t.verifyTrue(fsd.project.validateVehicleConcept(c));
            d=fsd.project.deriveVehicleConcept(c,o); t.verifyEmpty(d.values{1}.value); t.verifyEmpty(d.loads);
            t.verifyTrue(any(d.missing=="VEHICLE_MASS:RULE_IS_NOT_A_PHYSICAL_INPUT"));
            t.verifyTrue(fsd.project.validateConceptDerivation(d,c));
            r=fsd.project.designReadiness(p,'STATIC'); prepared=fsd.project.prepareEngineeringScenario(p,'STATIC');
            t.verifyEqual(r.status,"MISSING_DATA"); t.verifyEqual(prepared.readiness,r);
            t.verifyTrue(any(r.missing=="VEHICLE_MASS:RULE_IS_NOT_A_PHYSICAL_INPUT"));
            t.verifyError(@()fsd.project.runEngineeringScenario(p,'STATIC','INVALID'),'fsd:project:InvalidInput');
            definition=p.definition; definition.derivations={d}; saved=fsd.project.createEngineeringProject(definition);
            file=string(tempname)+".mat"; t.addTeardown(@()removeFile(file));
            fsd.project.saveEngineeringProject(saved,file); loaded=fsd.project.loadEngineeringProject(file);
            t.verifyEqual(loaded,saved); t.verifyEqual(p,before); t.verifyEmpty(loaded.definition.results);
        end
        function allConceptQuantitiesRespectRole(t,Quantity)
            values=[125,64.8,2.4,1.4,1.2,.9,0,.37,.625,.375,1,1,1,1,.25,.25,.1,.1];
            names=string(t.Quantity); value=values(names==Quantity);
            [p,c,o]=rulePhysicalInputFixture("RULE",Quantity,value);
            d=fsd.project.deriveVehicleConcept(c,o);
            if ismember(Quantity,["VEHICLE_MASS","DRIVER_MASS"]), t.verifyEmpty(d.values{1}.value); end
            if ismember(Quantity,["VEHICLE_MASS","DRIVER_MASS","WHEELBASE","FRONT_TRACK","REAR_TRACK"])
                t.verifyEmpty(d.vehicle); t.verifyEqual(fsd.project.designReadiness(p,'STATIC').status,"MISSING_DATA");
            elseif startsWith(Quantity,"CG_")
                index=find(["CG_X","CG_Y","CG_Z"]==Quantity); t.verifyTrue(isnan(d.vehicle.cg_m(index)));
            elseif startsWith(Quantity,"UNSPRUNG_MASS_")
                index=find("UNSPRUNG_MASS_"+["FL","FR","RL","RR"]==Quantity);
                t.verifyTrue(isnan(d.vehicle.unsprungMass_kg(index)));
            end
            % Every catalog quantity, including stored wheel dimensions, is also
            % subject to the same gate when explicitly required by a scenario.
            def=t.IndependentProject.definition; def.concept=c; s=def.scenarios{1}.definition;
            s.conceptDependencies=Quantity; def.scenarios={fsd.project.createEngineeringScenario(s)};
            p=fsd.project.createEngineeringProject(def); r=fsd.project.designReadiness(p,'GEOMETRY');
            t.verifyEqual(r.status,"MISSING_DATA");
            t.verifyTrue(any(r.diagnostics=="CONCEPT:"+Quantity+":RULE_IS_NOT_A_PHYSICAL_INPUT"));
            t.verifyError(@()fsd.project.runEngineeringScenario(p,'GEOMETRY','BAD'),'fsd:project:InvalidInput');
        end
        function physicalRolesRemainUsable(t,PhysicalRole)
            [p,c,o]=rulePhysicalInputFixture(PhysicalRole); d=fsd.project.deriveVehicleConcept(c,o);
            t.verifyEqual(d.values{1}.value,189.8,'AbsTol',1e-12);
            t.verifyEqual(d.loads.totalNormalDemand_N,1841.06,'AbsTol',1e-10);
            t.verifyEqual(fsd.project.designReadiness(p,'STATIC').status,"READY");
            r=fsd.project.runEngineeringScenario(p,'STATIC','GOOD'); t.verifyTrue(fsd.project.validateEngineeringResult(r));
            native=fsd.analysis.analyzeStaticVehicleLoads(d.vehicle,d.loadCase);
            t.verifyEqual(r.nativePayload.analysis.cornerLoads_N,native.cornerLoads_N,'AbsTol',1e-10);
            t.verifyEqual(r.nativePayload.analysis.cornerLoads_N,[575.33125;575.33125;345.19875;345.19875],'AbsTol',1e-10);
            p=fsd.project.attachEngineeringResult(p,r); definition=p.definition; definition.derivations={d};
            p=fsd.project.createEngineeringProject(definition); file=string(tempname)+".mat"; t.addTeardown(@()removeFile(file));
            fsd.project.saveEngineeringProject(p,file); t.verifyEqual(fsd.project.loadEngineeringProject(file),p);
            q=c.definitionSI.parameters{cellfun(@(x)x.id=="VEHICLE_MASS",c.definitionSI.parameters)};
            t.verifyEqual(q.parameter.definitionSI.type,PhysicalRole);
            if PhysicalRole=="ASSUMED", t.verifyEqual(q.parameter.definitionSI.sourceKind,"ASSUMED"); end
        end
        function nonFactsRemainUnavailable(t,MissingRole)
            value=[]; if MissingRole=="TARGET", value=125; end
            [p,c,o]=rulePhysicalInputFixture(MissingRole,"VEHICLE_MASS",value);
            d=fsd.project.deriveVehicleConcept(c,o); t.verifyEmpty(d.values{1}.value);
            t.verifyEqual(fsd.project.designReadiness(p,'STATIC').status,"MISSING_DATA");
        end
        function normativeFractionCannotSupplyMissingCG(t)
            [p,c,o]=rulePhysicalInputFixture("RULE","FRONT_WEIGHT_FRACTION",.625);
            def=c.definitionSI; def.parameters=def.parameters(~cellfun(@(q)q.id=="CG_X",def.parameters));
            c=fsd.project.createVehicleConcept(def); def=p.definition; def.concept=c; p=fsd.project.createEngineeringProject(def);
            d=fsd.project.deriveVehicleConcept(c,o); t.verifyTrue(isnan(d.vehicle.cg_m(1)));
            t.verifyEqual(fsd.project.designReadiness(p,'STATIC').status,"MISSING_DATA");
        end
        function ruleIntervalCannotBecomeAssumption(t)
            [~,c]=rulePhysicalInputFixture(); def=c.definitionSI; i=cellfun(@(q)q.id=="VEHICLE_MASS",def.parameters);
            p=def.parameters{i}; d=p.parameter.definitionSI; d=rmfield(d,{'id','quantity','unit','scope','binding'});
            d.bounds=[100,150]; def.parameters{i}=fsd.project.createConceptParameter('VEHICLE_MASS',d,'kg');
            c=fsd.project.createVehicleConcept(def); before=c;
            selection={struct('id',"VEHICLE_MASS",'value',125,'unit',"kg",'sourceNote',"Explicit choice")};
            t.verifyError(@()fsd.project.selectConceptValues(c,selection),'fsd:project:InvalidInput'); t.verifyEqual(c,before);
        end
        function physicalRangeRequiresExplicitSelection(t)
            [~,c,o]=rulePhysicalInputFixture("RANGE","VEHICLE_MASS",[]);
            chosen=fsd.project.selectConceptValues(c,{struct('id',"VEHICLE_MASS",'value',125,'unit',"kg",'sourceNote',"Explicit physical sample")});
            d=fsd.project.deriveVehicleConcept(chosen,o); t.verifyEqual(d.values{1}.value,189.8,'AbsTol',1e-12);
        end
        function derivedEvidenceRequiresOriginalDependencies(t)
            [~,c,o]=rulePhysicalInputFixture("ASSUMED"); d=fsd.project.deriveVehicleConcept(c,o);
            bad=d; bad.values{1}.dependencies="WHEELBASE";
            t.verifyError(@()fsd.project.validateConceptDerivation(bad),'fsd:project:InvalidConceptDerivation');
            [~,changed]=rulePhysicalInputFixture("ASSUMED","VEHICLE_MASS",130);
            t.verifyError(@()fsd.project.validateConceptDerivation(d,changed),'fsd:project:InvalidConceptDerivation');
            t.verifyError(@()rulePhysicalInputFixture("DERIVED","VEHICLE_MASS",125,"UNVERIFIED","VERIFIED"),'fsd:project:InvalidInput');
        end
        function rejectsOldSemanticEvidenceAcrossRoutes(t,LegacyRoute)
            file=string(tempname)+".mat"; t.addTeardown(@()removeFile(file));
            switch LegacyRoute
                case "DERIVATION", action=@()fsd.project.validateConceptDerivation(t.LegacyDerivation);
                case "RESULT", action=@()fsd.project.validateEngineeringResult(t.LegacyResult);
                case "PROJECT", action=@()fsd.project.validateEngineeringProject(t.LegacyProject);
                case "ATTACH", action=@()fsd.project.attachEngineeringResult(rulePhysicalInputFixture(),t.LegacyResult);
                case "COMPATIBILITY", action=@()fsd.project.resultCompatibility(t.LegacyResult,t.PhysicalProject);
                case "SAVE", action=@()fsd.project.saveEngineeringProject(t.LegacyProject,file);
                case "LOAD"
                    envelope=struct('kind',"FsdEngineeringProjectFile",'schemaVersion',"0.16.0",'project',t.LegacyProject);
                    save(file,'envelope'); action=@()fsd.project.loadEngineeringProject(file);
            end
            report=exceptionReport(action); t.verifyTrue(contains(report,"VEHICLE_MASS:RULE_IS_NOT_A_PHYSICAL_INPUT"),report);
            t.verifyEqual(t.LegacyDerivation.values{1}.value,189.8,'AbsTol',1e-12);
            t.verifyEqual(t.LegacyResult.nativePayload.analysis.totalNormalDemand_N,1841.06,'AbsTol',1e-10);
        end
        function selectiveRevisionNeverReparentsEvidence(t,Revision)
            p=fsd.project.attachEngineeringResult(t.IndependentProject,t.IndependentResult); before=p;
            switch Revision
                case "RULE_VALUE", [~,c]=rulePhysicalInputFixture("RULE","VEHICLE_MASS",130);
                case "RULE_TO_ASSUMED", [~,c]=rulePhysicalInputFixture("ASSUMED");
                case "PHYSICAL_VALUE"
                    [~,c]=rulePhysicalInputFixture("ASSUMED"); p=fsd.project.reviseEngineeringProject(p,struct('concept',c));
                    [~,c]=rulePhysicalInputFixture("ASSUMED","VEHICLE_MASS",130);
                case "RULE_REFERENCE", [~,c]=rulePhysicalInputFixture("RULE","VEHICLE_MASS",125,"VERIFIED");
                case "METADATA"
                    d=p.definition.concept.definitionSI; d.description="Irrelevant presentation description";
                    c=fsd.project.createVehicleConcept(d);
            end
            revised=fsd.project.reviseEngineeringProject(p,struct('concept',c));
            t.verifyEqual(fsd.project.resultCompatibility(t.IndependentResult,revised).status,"REUSABLE_DEPENDENCIES");
            t.verifyEqual(revised.definition.results{1},t.IndependentResult); t.verifyEqual(before.definition.results{1},t.IndependentResult);
            t.verifyGreaterThan(revised.definition.revision,p.definition.revision);
        end
        function physicalMassChangeMakesLoadsStale(t)
            p=fsd.project.attachEngineeringResult(t.PhysicalProject,t.PhysicalResult); before=p;
            [~,c]=rulePhysicalInputFixture("ASSUMED","VEHICLE_MASS",130);
            changed=fsd.project.reviseEngineeringProject(p,struct('concept',c));
            t.verifyEqual(fsd.project.resultCompatibility(t.PhysicalResult,changed).status,"STALE");
            new=fsd.project.runEngineeringScenario(changed,'STATIC','NEW');
            t.verifyEqual(new.nativePayload.analysis.totalNormalDemand_N,1889.56,'AbsTol',1e-10);
            t.verifyEqual(p,before); t.verifyEqual(changed.definition.results{1},t.PhysicalResult);
            rule=rulePhysicalInputFixture(); changed=fsd.project.reviseEngineeringProject(p,struct('concept',rule.definition.concept));
            t.verifyEqual(fsd.project.resultCompatibility(t.PhysicalResult,changed).status,"STALE");
            t.verifyTrue(fsd.project.validateEngineeringProject(changed));
        end
        function explicitRoleTransitionUnblocksWithoutMutation(t)
            p=rulePhysicalInputFixture(); before=p; [~,c]=rulePhysicalInputFixture("ASSUMED");
            revised=fsd.project.reviseEngineeringProject(p,struct('concept',c));
            t.verifyEqual(fsd.project.designReadiness(revised,'STATIC').status,"READY");
            t.verifyEqual(fsd.project.designReadiness(p,'STATIC').status,"MISSING_DATA"); t.verifyEqual(p,before);
        end
        function readinessAndValidatorsDoNotExecutePhysics(t)
            file=string(tempname)+".mat"; t.addTeardown(@()removeFile(file)); t.addTeardown(@()profile('off'));
            p=rulePhysicalInputFixture(); physical=fsd.project.attachEngineeringResult(t.PhysicalProject,t.PhysicalResult);
            profile clear; profile on;
            fsd.project.designReadiness(p,'STATIC'); fsd.project.prepareEngineeringScenario(p,'STATIC');
            exceptionReport(@()fsd.project.runEngineeringScenario(p,'STATIC','BLOCKED'));
            fsd.project.validateEngineeringResult(t.PhysicalResult);
            exceptionReport(@()fsd.project.validateEngineeringResult(t.LegacyResult));
            exceptionReport(@()fsd.project.validateConceptDerivation(t.LegacyDerivation));
            fsd.project.saveEngineeringProject(physical,file); fsd.project.loadEngineeringProject(file);
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["executeScenarioCore","analyzeStaticVehicleLoadsCore", ...
                "solveBump","solveActuation","solveRack","solveAxleRoll","fsolve","fzero","boundedDirectSearch"])));
        end
    end
end

function report = exceptionReport(action)
report="NO_EXCEPTION";
try
    action();
catch cause
    report=string(getReport(cause,'extended','hyperlinks','off'));
end
end

function removeFile(file)
if isfile(file), delete(file); end
end
