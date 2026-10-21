function valid=validateEngineeringResult(result)
%VALIDATEENGINEERINGRESULT Reconstruct original context and native evidence.
context=validationContext(); valid=context.result(result);
end
