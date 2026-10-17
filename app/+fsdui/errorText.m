function text = errorText(cause)
%ERRORTEXT Preserve original identifiers and nested native diagnostics.
text=string(cause.identifier)+": "+string(cause.message);
for j=1:numel(cause.cause), text=[text;fsdui.errorText(cause.cause{j})]; end %#ok<AGROW>
end
