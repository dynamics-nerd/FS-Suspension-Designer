classdef TestGuidedDesignInputs < matlab.unittest.TestCase
    properties (TestParameter)
        InvalidText = {'NaN','Inf','1:3','system(''x'')','[1 2]','1+2','1i'}
        Corner = {'FL','FR','RL','RR','FRONT'}
    end
    methods (TestMethodSetup)
        function paths(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
        end
    end
    methods (Test)
        function rejectsExpressionsAndNonfinite(t,InvalidText)
            t.verifyError(@()fsdui.numberList(InvalidText),'fsd:ui:InvalidNumber');
        end
        function numericParserAndUnknown(t)
            t.verifyEqual(fsdui.numberList('-.01, 0; +1e-2'),[-.01;0;.01]);
            t.verifyEmpty(fsdui.numberList(''));
        end
        function allDecisionRowsRoundTrip(t,Corner)
            [~,d]=parametricSeedInputs(Corner); catalog=fsd.construction.seedParameterCatalog();
            side=string(Corner); if side=="FRONT", side="FL"; end
            rows=fsdui.parameterRows(catalog,d.definitionSI.parameters,false);
            ps=fsdui.parametersFromRows(rows,d.definitionSI.parameters,side,false);
            dd=d.definitionSI; dd.parameters=ps;
            actual=fsd.construction.createParametricSeedDefinition(dd);
            t.verifyEqual(actual,d); t.verifySize(rows,[28 11]);
        end
        function conceptRowsPreserveProvenance(t)
            [c,~]=parametricSeedInputs('FL'); catalog=fsd.project.conceptParameterCatalog();
            rows=fsdui.parameterRows(catalog,c.definitionSI.parameters,true);
            ps=fsdui.parametersFromRows(rows,c.definitionSI.parameters,"",true);
            d=c.definitionSI; d.parameters=ps; actual=fsd.project.createVehicleConcept(d);
            for j=1:numel(c.definitionSI.parameters)
                p=c.definitionSI.parameters{j}; found=cellfun(@(q)q.id==p.id,actual.definitionSI.parameters);
                t.verifyEqual(actual.definitionSI.parameters{found},p);
            end
            % Editing a note must not erase metadata or an unsupported-data diagnostic.
            id=c.definitionSI.parameters{1}.id; unit=c.definitionSI.parameters{1}.parameter.definitionSI.unit;
            marker=struct('auditMarker',"EDITED_NOTE_METADATA");
            unsupported=fsd.project.createConceptParameter(id,struct('type',"KNOWN", ...
                'availability',"NOT_PROVIDED",'state',"UNSUPPORTED", ...
                'diagnostics',"Software-only unsupported datum",'metadata',marker),unit);
            rows=fsdui.parameterRows(catalog,{unsupported},true); k=string(rows(:,1))==id;
            rows{k,8}='Edited source note; still unsupported';
            edited=fsdui.parametersFromRows(rows,{unsupported},"",true);
            found=cellfun(@(q)q.id==id,edited); edited=edited{found};
            t.verifyEqual(edited.parameter.metadata,marker);
            t.verifyEqual(edited.state,unsupported.state); t.verifyEqual(edited.diagnostics,unsupported.diagnostics);
            t.verifyEqual(edited.origin,unsupported.origin);
        end
        function emptyConceptIsNotPhysicalZero(t)
            rows=fsdui.parameterRows(fsd.project.conceptParameterCatalog(),{},true);
            ps=fsdui.parametersFromRows(rows,{},"",true);
            t.verifyTrue(all(cellfun(@(p)isempty(p.parameter.definitionSI.value),ps)));
            c=fsd.project.createVehicleConcept(struct('id',"EMPTY",'parameters',{ps}));
            d=fsdui.seedDefinition(fsd.project.createEngineeringProject(struct('concept',c)),"FL");
            t.verifyEmpty(d.definitionSI.parameters);
        end
        function rangeHasNoImplicitMidpoint(t)
            c=fsd.project.createConceptParameter('FRONT_TRACK',struct('type',"RANGE",'bounds',[1 2], ...
                'sourceKind',"ASSUMED",'sourceNote',"Test interval; no nominal"),'m');
            rows=fsdui.parameterRows(fsd.project.conceptParameterCatalog(),{c},true);
            ps=fsdui.parametersFromRows(rows,{c},"",true); found=cellfun(@(p)p.id=="FRONT_TRACK",ps);
            t.verifyEmpty(ps{found}.parameter.definitionSI.value);
        end
        function unknownDecisionRemainsUnknown(t)
            rows=fsdui.parameterRows(fsd.construction.seedParameterCatalog(),{},false);
            ps=fsdui.parametersFromRows(rows,{},"FL",false);
            t.verifyTrue(all(cellfun(@(p)isempty(p.definitionSI.value),ps)));
        end
    end
end
