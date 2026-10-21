classdef TestPackagingPresentation < matlab.unittest.TestCase
    methods (TestClassSetup)
        function paths(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
        end
    end
    methods (Test)
        function editableRoundTripAndAtomicFailure(t)
            [~,g]=packagingMotionFixture(.04); d=packagingInputs(g,1);
            [v,p,r]=fsdui.packagingRows(d);
            t.verifyEqual(fsdui.packagingFromRows(d.definitionSI.id,v,p,r,g.referenceFrame,d),d);
            t.verifyEmpty(v{2,11}); t.verifyEmpty(r{1,6});
            v{1,6}='D: 0.008'; v{2,6}='D: 0.008';
            t.verifyEqual(fsdui.packagingFromRows(d.definitionSI.id,v,p,r,g.referenceFrame,d),d);
            v{2,7}='NaN 0 0'; before=d;
            t.verifyError(@()fsdui.packagingFromRows('DEMO_PACKAGING',v,p,r,g.referenceFrame,d),'fsd:ui:InvalidNumber');
            t.verifyEqual(d,before);
            % An imported incompatible frame must survive an ordinary edit;
            % renaming its ID must not silently assign the selected corner frame.
            imported=d.definitionSI;
            volume=imported.volumes{1}.definitionSI; volume.frame.id="OTHER_FRAME";
            imported.volumes{1}=fsd.packaging.createVolume(volume,'m');
            imported.pairs=cell(0,1); imported=fsd.packaging.createDefinition(imported);
            [v,p,r]=fsdui.packagingRows(imported);
            t.verifyEqual(fsdui.packagingFromRows(imported.definitionSI.id,v,p,r,g.referenceFrame,imported),imported);
            v{1,1}='RENAMED_VOLUME';
            t.verifyError(@()fsdui.packagingFromRows(imported.definitionSI.id,v,p,r,g.referenceFrame,imported), ...
                'fsd:ui:PackagingFrame');
        end
        function storedPlotHasActualPoseAndWitnesses(t)
            [d,g]=packagingMotionFixture(.04);
            sweep=fsd.kinematics.solveBumpSweep(g,[0;.04;.08],'m');
            result=fsd.packaging.evaluate(d,g,struct('mode',"BUMP",'requested_m',[0;.04;.08]),sweep);
            fig=figure('Visible','off'); t.addTeardown(@()delete(fig)); ax=axes(fig);
            h=fsd.packaging.plotResult(result,ax,2,result.worstCheckIndex);
            t.verifyEqual(ax.UserData.sampleIndex,2); t.verifyEqual(ax.UserData.pairStatus,"COLLISION_DETECTED");
            t.verifyEqual(string(ax.Title.String),["COLLISION_DETECTED";"BUMP sample 2"]);
            t.verifyNumElements(h.volumes,2); t.verifyEmpty(h.witnesses);
            h=fsd.packaging.plotResult(result,ax,1,1);
            t.verifyNotEmpty(h.witnesses);
            t.verifyEqual(h.witnesses.XData,result.checks{1}.witnesses_m(:,1)');
        end
    end
end
