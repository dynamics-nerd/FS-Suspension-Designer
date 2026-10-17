function stamp = fileStamp(file)
%FILESTAMP Detect destination replacement while a save is in flight.
stamp=[];
if isfile(file)
    d=dir(file); stamp=struct('bytes',d.bytes,'datenum',d.datenum);
end
end
