function report = verifyV16F01(mode)
%VERIFYV16F01 Focused public-API reproducer; LEGACY must run BEFORE the fix.
if nargin<1, mode="FIXED"; end
root=fileparts(fileparts(mfilename('fullpath'))); old=path;
cleanup=onCleanup(@()path(old)); addpath(fullfile(root,'src'));
[project,concept,options]=rulePhysicalInputFixture();
[legacyDerivation,legacyResult,legacyProject]=legacyRuleEvidence();
if mode=="LEGACY"
    derivation=fsd.project.deriveVehicleConcept(concept,options);
    result=fsd.project.runEngineeringScenario(project,'STATIC','OLD_RULE');
    assert(fsd.project.validateConceptDerivation(legacyDerivation));
    assert(fsd.project.validateEngineeringResult(legacyResult));
    assert(fsd.project.validateEngineeringProject(legacyProject));
    assert(isequaln(stripClocks(derivation),stripClocks(legacyDerivation)));
    assert(isequaln(stripClocks(result),stripClocks(legacyResult)));
    file=fullfile(root,'output','v016-f01-legacy-project.mat');
    fsd.project.saveEngineeringProject(legacyProject,file,true); loaded=fsd.project.loadEngineeringProject(file);
    assert(isequaln(legacyProject,loaded));
    report=struct('mode',mode,'mass_kg',derivation.values{1}.value, ...
        'normal_N',result.nativePayload.analysis.totalNormalDemand_N,'readiness',result.prepared.readiness.status, ...
        'legacyFixtureMatchesActualPublicExecution',true);
    save(fullfile(root,'output','v016-f01-before.mat'),'report','derivation','result');
else
    assert(mode=="FIXED");
    r=runtests(fullfile(root,'tests','TestRulePhysicalInput.m'));
    assert(all([r.Passed])); report=struct('mode',mode,'results',r);
    save(fullfile(root,'output','v016-f01-focused.mat'),'report');
end
disp(report);
end

function value = stripClocks(value)
if isstruct(value)
    for j=1:numel(value)
        for name=string(fieldnames(value))'
            if endsWith(lower(name),'elapsedtime_s'), value(j).(name)=0;
            else, value(j).(name)=stripClocks(value(j).(name)); end
        end
    end
elseif iscell(value)
    for j=1:numel(value), value{j}=stripClocks(value{j}); end
end
end
