function values = numberList(text)
%NUMBERLIST Parse data, never MATLAB expressions or executable user input.
if isnumeric(text), values=text; else
    text=strtrim(string(text));
    if strlength(text)==0, values=[]; return; end
    tokens=regexp(char(text),'[\s,;]+','split');
    valid=cellfun(@(s)~isempty(regexp(s,'^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$','once')),tokens);
    if ~all(valid), error('fsd:ui:InvalidNumber','Enter finite numbers separated by spaces, commas or semicolons; expressions are not accepted.'); end
    values=str2double(tokens);
end
if ~isreal(values) || any(~isfinite(values),'all'), error('fsd:ui:InvalidNumber','Finite real numbers required.'); end
values=double(values(:));
end
