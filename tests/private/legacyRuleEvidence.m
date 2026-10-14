function [derivation,result,project] = legacyRuleEvidence()
%LEGACYRULEEVIDENCE Encode the OLD semantic defect, never a production adapter.
% Native physics is genuine. Only the concept's meaning/context is replaced.
% verifyV16F01('LEGACY') checks this against actual pre-fix public execution.
[physical,concept,options]=rulePhysicalInputFixture("ASSUMED");
[normative,rule]=rulePhysicalInputFixture();
derivation=fsd.project.deriveVehicleConcept(concept,options);
result=fsd.project.runEngineeringScenario(physical,'STATIC','OLD_RULE');
derivation=replaceContext(derivation,concept,rule);
result=replaceContext(result,concept,rule);
project=normative;
project.definition.derivations={derivation}; project.definition.results={result};
end

function value = replaceContext(value,physical,rule)
if isequaln(value,physical), value=rule; return; end
if isequaln(value,physical.identity), value=rule.identity; return; end
if isstruct(value)
    for j=1:numel(value)
        for name=string(fieldnames(value))'
            value(j).(name)=replaceContext(value(j).(name),physical,rule);
        end
    end
elseif iscell(value)
    for j=1:numel(value), value{j}=replaceContext(value{j},physical,rule); end
end
end
