classdef TestGuidedActuationVariants < matlab.unittest.TestCase
    methods(TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
        end
    end
    methods(Test)
        function declaredArchitecturesAndBodiesRemainDistinct(t)
            [p,~,s]=guidedActuationFixture(); [rows,m,c,r]=fsdui.actuationRows(s.seedActuation,s.seedMechanical);
            identities=cell(6,1); j=0;
            for type=["PUSHROD","PULLROD"]
                for body=["UPRIGHT","UCA","LCA"]
                    args=fsdui.actuationConfiguration('FL',type,body,'YZ_PLANE',rows,false,'LINEAR_ASYMMETRIC',m,c,r);
                    [~,a]=fsd.project.configureActuationResources(p,args.cornerId,args.definition,args.lengthUnit,[],args.units);
                    t.verifyEqual(a.actuationType,type); t.verifyEqual(a.suspensionAttachment.body,body);
                    j=j+1; identities{j}=a.identity;
                end
            end
            for j=1:6, for k=j+1:6, t.verifyNotEqual(identities{j},identities{k}); end, end
        end
        function tabulatedDampingKeepsUnitsSourcesAndUnknownLimits(t)
            [p,~,s]=guidedActuationFixture(); [rows,m]=fsdui.actuationRows(s.seedActuation,s.seedMechanical);
            m(4:8,2)=repmat({''},5,1);
            comp={0,0;100,100;200,90}; rebound={0,0;100,200;200,250};
            args=fsdui.actuationConfiguration('FL','PUSHROD','UPRIGHT','YZ_PLANE',rows,true, ...
                'TABULATED_FORCE_VELOCITY',m,comp,rebound);
            [~,~,model]=fsd.project.configureActuationResources(p,args.cornerId,args.definition,args.lengthUnit,args.mechanicalDefinition,args.units);
            t.verifyEqual(model.damper.compressionTable,[0 0;.1 100;.2 90]);
            t.verifyEqual(model.damper.reboundTable,[0 0;.1 200;.2 250]);
            t.verifyEmpty(model.spring.solidHeight_m); t.verifyEmpty(model.damper.minimumLength_m);
            t.verifyEmpty(model.damper.maximumLength_m);
            t.verifyEqual(model.metadata.parameterProvenance.COMPRESSION_COEFFICIENT.sourceKind,"ASSUMED");
            [~,~,co,re]=fsdui.actuationRows(s.seedActuation,model);
            t.verifyEqual(co,comp); t.verifyEqual(re,rebound);
        end
        function presetContradictionIsRejectedByNativeFactory(t)
            [p,~,s]=guidedActuationFixture(); [rows,m,c,r]=fsdui.actuationRows(s.seedActuation,s.seedMechanical);
            rows(3,2:4)={0,1,0};
            args=fsdui.actuationConfiguration('FL','PUSHROD','UPRIGHT','YZ_PLANE',rows,false,'LINEAR_ASYMMETRIC',m,c,r);
            t.verifyError(@()fsd.project.configureActuationResources(p,args.cornerId,args.definition,args.lengthUnit,[],args.units), ...
                'fsd:model:InvalidActuationDefinition');
        end
        function customAxisRequiresExplicitProvenance(t)
            [~,~,s]=guidedActuationFixture(); [rows,m,c,r]=fsdui.actuationRows(s.seedActuation,s.seedMechanical);
            rows{3,7}='';
            t.verifyError(@()fsdui.actuationConfiguration('FL','PUSHROD','UPRIGHT','CUSTOM',rows,false,'LINEAR_ASYMMETRIC',m,c,r), ...
                'fsd:ui:ActuationInput');
        end
    end
end
