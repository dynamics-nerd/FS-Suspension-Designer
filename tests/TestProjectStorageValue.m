classdef TestProjectStorageValue < matlab.unittest.TestCase
    methods (TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'src'));
        end
    end
    methods (Test)
        function exactPlainClassesShapesAndMissingness(t)
            text=[" a  ",missing;"<missing>","ñ—μ"];
            value=struct('text',text,'empty',strings(0,3),'char',char([945 946]), ...
                'numbers',[NaN Inf -Inf -0.0],'integer',uint64([0 intmax('uint64')]), ...
                'logical',logical(eye(2)),'single',single([1 NaN]),'complex',1+2i,'sparse',sparse(eye(3)));
            encoded=fsd.project.encodeStorageValue(value);
            actual=fsd.project.decodeStorageValue(encoded); t.verifyEqual(actual,value);
            t.verifyEqual(1/actual.numbers(4),-Inf);
            t.verifyFalse(containsString(encoded));
        end
        function arbitraryReservedNamesCannotCollide(t)
            original=struct('fsdTextStorageV1',{{[1 1],{'literal'},false}}, ...
                'fsdStructStorageV1',struct('text',"not a marker"));
            value={original,repmat(original,[2 1]),repmat(original,[0 3]),struct(),cell(0,2)};
            t.verifyEqual(fsd.project.decodeStorageValue(fsd.project.encodeStorageValue(value)),value);
        end
        function malformedMarkersAreRejected(t)
            bad=struct('fsdTextStorageV1',{{[2 2],{'a'},false}});
            t.verifyError(@()fsd.project.decodeStorageValue(bad),'fsd:project:InvalidInput');
            bad=struct('fsdStructStorageV1',1);
            t.verifyError(@()fsd.project.decodeStorageValue(bad),'fsd:project:InvalidInput');
            t.verifyError(@()fsd.project.encodeStorageValue(@sin),'fsd:project:InvalidInput');
            t.verifyError(@()fsd.project.decodeStorageValue("not encoded"),'fsd:project:InvalidInput');
        end
        function nativeMatPreservesEncodedValues(t)
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            original={strings(0,2),["test",missing],uint8([0 255]),reshape(1:8,2,2,2)};
            storage=fsd.project.encodeStorageValue(original); file=fullfile(folder.Folder,'plain.mat');
            save(file,'storage','-v7'); restored=load(file,'storage');
            t.verifyEqual(fsd.project.decodeStorageValue(restored.storage),original);
        end
        function legacyAndPackagingProjectFiles(t)
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            concept=fsd.project.createVehicleConcept(struct('id',"STORAGE_CASE"));
            old=fsd.project.createEngineeringProject(struct('concept',concept));
            legacy=fullfile(folder.Folder,'legacy.mat'); fsd.project.saveEngineeringProject(old,legacy,false);
            raw=load(legacy,'envelope'); t.verifyEqual(raw.envelope.schemaVersion,"0.16.0");
            t.verifyEqual(fsd.project.loadEngineeringProject(legacy),old);
            resources=old.definition.resources; resources.packaging={};
            current=fsd.project.reviseEngineeringProject(old,struct('resources',resources));
            file=fullfile(folder.Folder,'current.mat'); fsd.project.saveEngineeringProject(current,file,false);
            raw=load(file,'envelope'); t.verifyEqual(raw.envelope.kind,'FsdEngineeringProjectStorage');
            t.verifyEqual(fsd.project.loadEngineeringProject(file),current);
        end
        function malformedPhysicalStorageCannotBypassProjectValidation(t)
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            p=fsd.project.createEngineeringProject(struct('concept', ...
                fsd.project.createVehicleConcept(struct('id',"STORAGE_CASE")),'resources',struct('packaging',{{}})));
            file=fullfile(folder.Folder,'tampered.mat'); fsd.project.saveEngineeringProject(p,file,false);
            raw=load(file,'envelope'); envelope=raw.envelope; envelope.resultNames={'FSD_RESULT_000001'};
            save(file,'envelope','-v7');
            t.verifyError(@()fsd.project.loadEngineeringProject(file),'fsd:project:InvalidInput');
            fsd.project.saveEngineeringProject(p,file,true); raw=load(file,'envelope'); envelope=raw.envelope;
            configuration=fsd.project.decodeStorageGraph(envelope.configuration);
            configuration.identity=struct(); envelope.configuration=fsd.project.encodeStorageGraph(configuration);
            save(file,'envelope','-v7');
            t.verifyError(@()fsd.project.loadEngineeringProject(file),'fsd:project:InvalidInput');
        end
    end
end
function found=containsString(v)
found=isstring(v);
if isstruct(v)
    names=fieldnames(v);
    for j=1:numel(v), for k=1:numel(names), found=found || containsString(v(j).(names{k})); end, end
elseif iscell(v)
    for j=1:numel(v), found=found || containsString(v{j}); end
end
end
