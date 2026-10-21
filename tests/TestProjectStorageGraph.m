classdef TestProjectStorageGraph < matlab.unittest.TestCase
    methods (TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'src'));
        end
    end
    methods (Test)
        function exactClassesShapesBitsAndLiteralMarkerFields(t)
            tagged=struct('schemaVersion',"TEST",'kind',"NODE",'id',"SAME_ID",'value',0);
            data={0,-0.0,single(0),complex(0,0),sparse(0),uint8(0),NaN, ...
                zeros(0,3),zeros(0,2),strings(0,3),strings(0,2)};
            variants=cell(numel(data),1);
            for j=1:numel(data), v=tagged; v.value=data{j}; variants{j}=v; end
            original={variants,variants,struct('fsdValueGraphV1',"literal"), ...
                [" a  ",missing;"<missing>","ñ—μ"],strings(0,3), ...
                repmat(tagged,[0 3]),repmat(tagged,[2 1]),struct(),cell(0,2), ...
                reshape(uint64(1:8),2,2,2),[NaN Inf -Inf -0.0],1+2i,sparse(eye(3)),char([945 946]), ...
                struct('end',1,'while',uint8(2)),string(char([65 0 66]))};
            encoded=fsd.project.encodeStorageGraph(original);
            actual=fsd.project.decodeStorageGraph(encoded); t.verifyEqual(actual,original);
            for j=1:numel(data)
                t.verifyClass(actual{1}{j}.value,class(data{j}));
                t.verifySize(actual{1}{j}.value,size(data{j}));
                t.verifyEqual(issparse(actual{1}{j}.value),issparse(data{j}));
                t.verifyEqual(isreal(actual{1}{j}.value),isreal(data{j}));
            end
            t.verifyEqual(1/actual{1}{2}.value,-Inf); t.verifyEqual(1/actual{1}{1}.value,Inf);
            t.verifyEqual(encoded.format,'FSD_VALUE_GRAPH_V1');
        end
        function equalTypedSubtreesShareOnlyWithinOneValue(t)
            item=struct('schemaVersion',"TEST",'kind',"NODE",'id',"REPEATED", ...
                'data',repmat("repeat",1,100),'array',reshape(1:100,10,10));
            once=fsd.project.encodeStorageGraph(item);
            repeated=fsd.project.encodeStorageGraph({item;item;item});
            t.verifyEqual(numel(repeated.nodes),numel(once.nodes)+1);
            changed=item; changed.array(1)=2;
            mixed=fsd.project.decodeStorageGraph(fsd.project.encodeStorageGraph({item,changed}));
            t.verifyEqual(mixed,{item,changed}); t.verifyNotEqual(mixed{1},mixed{2});
            changed=item; changed.data(1)="new";
            t.verifyEqual(fsd.project.decodeStorageGraph(fsd.project.encodeStorageGraph(changed)),changed);
        end
        function repeatedFieldListsRetainOrderAndUnambiguousBoundaries(t)
            a=struct('AB',1,'C',2); b=struct('A',1,'BC',2);
            original={repmat(a,2,1);repmat(a,1,2);b;orderfields(a,{'C','AB'});struct()};
            encoded=fsd.project.encodeStorageGraph(original);
            actual=fsd.project.decodeStorageGraph(encoded);
            t.verifyEqual(actual,original);
            t.verifyEqual(fieldnames(actual{4}),{'C';'AB'});
            changed=original; changed{2}(2).AB=3;
            t.verifyEqual(fsd.project.decodeStorageGraph(fsd.project.encodeStorageGraph(changed)),changed);
        end
        function malformedAndForwardReferencesAreRejected(t)
            encoded=fsd.project.encodeStorageGraph({"text",1});
            bad=encoded; bad.nodes{end}{2}(1)=bad.root;
            t.verifyError(@()fsd.project.decodeStorageGraph(bad),'fsd:project:InvalidInput');
            bad=encoded; bad.types(end)=uint8(255);
            t.verifyError(@()fsd.project.decodeStorageGraph(bad),'fsd:project:InvalidInput');
            bad=encoded; bad.root=double(bad.root);
            t.verifyError(@()fsd.project.decodeStorageGraph(bad),'fsd:project:InvalidInput');
            t.verifyError(@()fsd.project.encodeStorageGraph(@sin),'fsd:project:InvalidInput');
            t.verifyError(@()fsd.project.decodeStorageGraph(struct()),'fsd:project:InvalidInput');
        end
        function unversionedContainersShareByExactChildren(t)
            item=struct('point',[0 -0.0 1],'flag',true,'text',"same");
            once=fsd.project.encodeStorageGraph(item);
            repeated=fsd.project.encodeStorageGraph({item;item;item});
            t.verifyEqual(numel(repeated.nodes),numel(once.nodes)+1);
            actual=fsd.project.decodeStorageGraph(repeated);
            t.verifyEqual(actual,{item;item;item}); t.verifyEqual(1/actual{1}.point(2),-Inf);
            large=reshape(1:1000,20,50); value={large,large,sparse(eye(3))};
            t.verifyEqual(fsd.project.decodeStorageGraph(fsd.project.encodeStorageGraph(value)),value);
        end
        function cooperativeConversionPreservesRepresentationAndCanStop(t)
            original=num2cell(1:600); calls=0;
            expected=fsd.project.encodeStorageGraph(original);
            encoded=fsd.project.encodeStorageGraph(original,@visit);
            t.verifyEqual(encoded,expected); t.verifyGreaterThan(calls,2);
            calls=0; actual=fsd.project.decodeStorageGraph(encoded,@visit);
            t.verifyEqual(actual,original); t.verifyGreaterThan(calls,2);
            stop=@()error('fsd:test:ConversionStopped','Explicit software cancellation.');
            t.verifyError(@()fsd.project.encodeStorageGraph(original,stop),'fsd:test:ConversionStopped');
            t.verifyError(@()fsd.project.decodeStorageGraph(encoded,stop),'fsd:test:ConversionStopped');
            t.verifyEqual(fsd.project.decodeStorageGraph(expected),original);
            function visit()
                calls=calls+1;
            end
        end
        function nativeMatRoundTrip(t)
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            original={strings(0,2),["text",missing],uint64(intmax('uint64')),complex(1,0),sparse(eye(3))};
            storage=fsd.project.encodeStorageGraph(original); file=fullfile(folder.Folder,'graph.mat');
            save(file,'storage','-v7'); restored=load(file,'storage');
            t.verifyEqual(fsd.project.decodeStorageGraph(restored.storage),original);
        end
        function nonPackagingHistoryUsesBoundedStorageAndReadsLegacy(t)
            p=projectWorkflowFixture('BUMP');
            [~,p]=fsd.project.runEngineeringScenario(p,'SCENARIO','NATIVE_HISTORY');
            t.verifyFalse(isfield(p.definition.resources,'packaging'));
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            legacy=fullfile(folder.Folder,'legacy-history.mat');
            envelope=struct('kind',"FsdEngineeringProjectFile",'schemaVersion',"0.16.0",'project',p);
            save(legacy,'envelope','-v7');
            t.verifyEqual(fsd.project.loadEngineeringProject(legacy),p);
            file=fullfile(folder.Folder,'bounded-history.mat');
            fsd.project.saveEngineeringProject(p,file,false);
            raw=load(file,'envelope');
            t.verifyEqual(raw.envelope.kind,'FsdEngineeringProjectStorage');
            t.verifyEqual(raw.envelope.encoding,'FSD_VALUE_GRAPH_V1');
            t.verifyEqual(raw.envelope.resultNames,{'FSD_RESULT_000001'});
            t.verifyEqual(fsd.project.loadEngineeringProject(file),p);
        end
        function textV1DevelopmentFilesRemainReadable(t)
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            p=fsd.project.createEngineeringProject(struct('concept', ...
                fsd.project.createVehicleConcept(struct('id',"OLD_PACKAGING")),'resources',struct('packaging',{{}})));
            envelope=struct('kind','FsdEngineeringProjectStorage','schemaVersion','0.19.0', ...
                'encoding','FSD_TEXT_V1','configuration',fsd.project.encodeStorageValue(p), ...
                'resultNames',{cell(1,0)},'resultShape',[0 1]);
            file=fullfile(folder.Folder,'old-text.mat'); save(file,'envelope','-v7');
            t.verifyEqual(fsd.project.loadEngineeringProject(file),p);
        end
    end
end
