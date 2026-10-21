function report=resultCompatibility(result,project)
%RESULTCOMPATIBILITY Canonical current/reusable/stale classification.
context=validationContext(); context.reference(result); context.project(project);
report=compatibilityCore(result,project,result.kind=="PackagingSourceReference",context);
end
