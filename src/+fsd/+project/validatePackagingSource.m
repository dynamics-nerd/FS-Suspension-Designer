function valid=validatePackagingSource(source)
%VALIDATEPACKAGINGSOURCE Verify the exact projected native context and evidence.
context=validationContext(); valid=context.source(source);
end
