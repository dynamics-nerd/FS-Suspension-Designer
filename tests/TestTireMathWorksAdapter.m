classdef TestTireMathWorksAdapter < matlab.unittest.TestCase
    % Optional-provider fidelity tests, not validation of real tire behavior.
    % Models created by new() are explicit synthetic/default test fixtures.
    properties(TestParameter)
        Family={"Fiala","Dugoff","MF52","MF62"}
    end
    methods(TestClassSetup)
        function paths(t)
            old=path; t.addTeardown(@()path(old));
            root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'src'));
        end
    end
    methods(Test)
        function publicExportImportPreservesProviderForces(t,Family)
            requireOptionalAPI(t); folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            model=tireModel.new(Family);
            file=fullfile(folder.Folder,'synthetic.tir'); export(model,string(file),overwrite=true);
            descriptor=fsd.tire.importMathWorksTir(file,"Synthetic provider defaults; not Formula Student tire data.");
            states=explicitStates(); data=providerData(states); expected=compute(tireModel.import(string(file)),data);
            actual=fsd.tire.evaluateMathWorks(descriptor,states);
            t.verifyEqual(actual.Fx_N,expected.Fx(:));
            t.verifyEqual(actual.Fy_N,expected.Fy(:));
            t.verifyEqual(actual.coordinateSystem,"ISO");
            t.verifyEqual(actual.provider.identifier,"VDYNTIRE");
            t.verifyEqual(descriptor.sourceText,fileread(file));
            t.verifyEqual(descriptor.evidence,"IMPORTED_UNVERIFIED");
            t.verifyTrue(isPlain(descriptor)); t.verifyTrue(isPlain(actual));
            if Family=="Dugoff", t.verifyEqual(descriptor.variant,"DUGOFF_MODIFIED");
            elseif Family=="Fiala", t.verifyEqual(descriptor.variant,"FIALA");
            else, t.verifyEqual(descriptor.variant,Family);
            end
        end

        function matPersistsPlainDescriptorExactlyWithoutSourceFile(t)
            requireOptionalAPI(t); folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            file=fullfile(folder.Folder,'original.tir'); model=tireModel.new('Dugoff');
            model.modified_dugoff=false; model.Ckappa=16000; model.Calpha=12000;
            export(model,string(file),overwrite=true);
            descriptor=fsd.tire.importMathWorksTir(file,"Synthetic nominal Dugoff fixture.");
            expected=fsd.tire.evaluateMathWorks(descriptor,explicitStates());
            mat=fullfile(folder.Folder,'descriptor.mat'); save(mat,'descriptor');
            delete(file); restored=load(mat,'descriptor');
            t.verifyEqual(restored.descriptor,descriptor);
            actual=fsd.tire.evaluateMathWorks(restored.descriptor,explicitStates());
            t.verifyEqual(actual.Fx_N,expected.Fx_N); t.verifyEqual(actual.Fy_N,expected.Fy_N);
            t.verifyEqual(descriptor.variant,"DUGOFF_NOMINAL");
        end

        function changedDescriptorAndSourceAreRejected(t)
            requireOptionalAPI(t); descriptor=makeDescriptor(t); s=explicitStates();
            altered=descriptor; altered.parameters.Ckappa=123;
            t.verifyError(@()fsd.tire.evaluateMathWorks(altered,s),'fsd:tire:InvalidMathWorksDescriptor');
            altered=descriptor; altered.parameters.Ckappa=123;
            altered.identity=rmfield(altered,'identity');
            t.verifyError(@()fsd.tire.evaluateMathWorks(altered,s),'fsd:tire:InvalidMathWorksDescriptor');
            altered=descriptor; altered.sourceFilename="../outside.tir";
            altered.identity=rmfield(altered,'identity');
            t.verifyError(@()fsd.tire.evaluateMathWorks(altered,s),'fsd:tire:InvalidMathWorksDescriptor');
        end

        function noAuxiliaryStateIsInferred(t)
            requireOptionalAPI(t); descriptor=makeDescriptor(t); s=explicitStates();
            for name=["Fz","alpha","kappa","gamma","Vx","IP","psidot","omega"]
                absent=rmfield(s,name);
                t.verifyError(@()fsd.tire.evaluateMathWorks(descriptor,absent),'fsd:tire:InvalidMathWorksStates');
            end
            s.IP=[]; t.verifyError(@()fsd.tire.evaluateMathWorks(descriptor,s),'fsd:tire:InvalidMathWorksStates');
        end

        function scalarExpansionIsExplicitAndProviderEquivalent(t)
            requireOptionalAPI(t); descriptor=makeDescriptor(t); s=explicitStates();
            actual=fsd.tire.evaluateMathWorks(descriptor,s);
            t.verifySize(actual.states.Vx,[3,1]);
            for k=1:3
                scalar=s; scalar.alpha=s.alpha(k); scalar.kappa=s.kappa(k);
                one=fsd.tire.evaluateMathWorks(descriptor,scalar);
                t.verifyEqual(actual.Fx_N(k),one.Fx_N); t.verifyEqual(actual.Fy_N(k),one.Fy_N);
            end
        end

        function declaredDomainIsRejectedRatherThanSilentlyClipped(t)
            requireOptionalAPI(t); descriptor=makeDescriptor(t); s=explicitStates();
            s.alpha=[0;descriptor.parameters.ALPMAX+.1;0];
            t.verifyError(@()fsd.tire.evaluateMathWorks(descriptor,s),'fsd:tire:MathWorksOutOfDomain');
            s=explicitStates(); s.Vx=0;
            t.verifyError(@()fsd.tire.evaluateMathWorks(descriptor,s),'fsd:tire:MathWorksOutOfDomain');
        end
    end
end
function requireOptionalAPI(t)
t.assumeTrue(~isempty(which('tireModel'))&&~isempty(which('tireData')), ...
    'Optional Extended Tire Features API absent: provider tests explicitly skipped.');
end
function descriptor=makeDescriptor(t)
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
file=fullfile(folder.Folder,'fixture.tir'); model=tireModel.new('Dugoff');
export(model,string(file),overwrite=true);
descriptor=fsd.tire.importMathWorksTir(file,"Synthetic provider-default fixture; not engineering tire data.");
end
function s=explicitStates()
% Constant values are explicitly supplied test conditions, never adapter defaults.
s=struct('Fz',4000,'alpha',[-.03;0;.03],'kappa',[-.02;0;.02], ...
    'gamma',0,'Vx',10,'IP',220000,'psidot',0,'omega',30);
end
function data=providerData(s)
data=tireData; names=string(fieldnames(s)); n=numel(s.alpha);
for name=names'
    value=s.(name); if isscalar(value), value=repmat(value,n,1); end
    data.(name)=value(:);
end
end
function tf=isPlain(v)
if isstruct(v), tf=all(cellfun(@isPlain,struct2cell(v)),'all');
elseif iscell(v), tf=all(cellfun(@isPlain,v),'all');
else, tf=isnumeric(v)||islogical(v)||ischar(v)||isstring(v);
end
end
