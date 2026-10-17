classdef TestGuidedDesignExtraJSON < matlab.unittest.TestCase
    properties (TestParameter)
        Conflict={'value','Value','VALUE','bounds','Bounds','role','Role','type','availability', ...
            'Availability','provenance','sourceKind','source_kind','source-kind','sourceNote', ...
            'confirmation','origin','state','id','unit','quantity','scope','binding','metadata'}
        BadJSON={'[]','[{}]','null','1','"text"','{','{"derivationReference":2}', ...
            '{"derivationReference":[]}','{"ruleReference":[]}', ...
            '{"ruleReference":{"value":2}}','{"ruleReference":{"source":2}}', ...
            '{"ruleReference":[{}]}','{"ruleReference":{},"ruleReference":{}}', ...
            '{"derivationReference":"a","derivationReference":"b"}', ...
            '{"rule Reference":{}}','{"\u0072uleReference":{}}', ...
            '{"rule Reference":{},"ruleReference":{}}', ...
            '{"\u0072uleReference":{},"ruleReference":{}}'}
        Role={'KNOWN','ASSUMED','RULE','TARGET','DERIVED'}
    end
    methods (TestMethodSetup)
        function paths(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
        end
    end
    methods (Test)
        function rejectsExplicitFieldsAndVariants(t,Conflict)
            [c,rows,k]=inputs(); rows{k,2}='1.61'; rows{k,11}=sprintf('{"%s":2.2}',Conflict);
            original=c;
            try
                fsdui.parametersFromRows(rows,c.definitionSI.parameters,"",true);
                t.assertFail('Conflicting JSON was accepted.');
            catch cause
                t.verifyEqual(cause.identifier,'fsd:ui:ExtraJSON');
                t.verifyTrue(contains(string(cause.message),"WHEELBASE"));
                t.verifyTrue(contains(string(cause.message),"Row "+k));
                t.verifyTrue(contains(string(cause.message),'key'));
            end
            t.verifyEqual(c,original);
        end
        function validatesObjectTypesAndReferenceFields(t,BadJSON)
            [c,rows,k]=inputs(); rows{k,11}=BadJSON;
            t.verifyError(@()fsdui.parametersFromRows(rows,c.definitionSI.parameters,"",true),'fsd:ui:ExtraJSON');
        end
        function permitsOnlyCanonicalComplementaryReferences(t,Role)
            [c,rows,k]=inputs(); rows{k,5}=Role;
            source='ASSUMED'; if strcmp(Role,'KNOWN'), source='KNOWN'; elseif strcmp(Role,'DERIVED'), source='DERIVED'; end
            rows{k,6}=source; rows{k,7}=source; rows{k,8}='Software-only provenance regression';
            reference=struct('organizer','TEST','version','TEST','ruleId','SOFTWARE_ONLY', ...
                'quantity','LENGTH','source','Test fixture, not a real rule', ...
                'status','UNVERIFIED','applicability','TEST');
            rows{k,11}=jsonencode(struct('ruleReference',reference,'derivationReference','SOFTWARE_CALCULATION'));
            ps=fsdui.parametersFromRows(rows,c.definitionSI.parameters,"",true);
            p=ps{cellfun(@(p)p.id=="WHEELBASE",ps)}.parameter.definitionSI;
            t.verifyEqual(p.type,string(Role)); t.verifyEqual(string(p.derivationReference),"SOFTWARE_CALCULATION");
            t.verifyEqual(p.ruleReference,reference); t.verifyEqual(p.value,1.6);
        end
        function seedEditorRejectsOverridesAndPreservesMetadata(t)
            [~,d]=parametricSeedInputs('FL'); ps=d.definitionSI.parameters;
            p=ps{1}.definitionSI; p.metadata=struct('marker',"KEPT"); p.description="Native unexposed description";
            ps{1}=fsd.model.createDesignParameter(p,'m');
            rows=fsdui.parameterRows(fsd.construction.seedParameterCatalog(),ps,false);
            k=find(string(rows(:,1))==p.id); rows{k,8}='Edited source note';
            rows{k,11}='{"derivationReference":"LEGITIMATE_REFERENCE"}';
            actual=fsdui.parametersFromRows(rows,ps,"FL",false);
            t.verifyEqual(actual{1}.metadata,ps{1}.metadata);
            t.verifyEqual(actual{1}.definitionSI.description,p.description);
            t.verifyEqual(string(actual{1}.definitionSI.derivationReference),"LEGITIMATE_REFERENCE");
            rows{k,11}='{"value":2.2}';
            t.verifyError(@()fsdui.parametersFromRows(rows,ps,"FL",false),'fsd:ui:ExtraJSON');
        end
        function referenceTextCannotBeMistakenForAKey(t)
            [c,rows,k]=inputs();
            note='Literal text: "derivationReference":"other", "ruleReference":[] and "value":2.2';
            rows{k,11}=jsonencode(struct('ruleReference',struct(),'derivationReference',note));
            ps=fsdui.parametersFromRows(rows,c.definitionSI.parameters,"",true);
            p=ps{cellfun(@(p)p.id=="WHEELBASE",ps)}.parameter.definitionSI;
            t.verifyEqual(string(p.derivationReference),string(note)); t.verifyEqual(p.value,1.6);
        end
    end
end
function [c,rows,k]=inputs()
[c,~]=parametricSeedInputs('FL');
rows=fsdui.parameterRows(fsd.project.conceptParameterCatalog(),c.definitionSI.parameters,true);
k=find(string(rows(:,1))=="WHEELBASE");
end
