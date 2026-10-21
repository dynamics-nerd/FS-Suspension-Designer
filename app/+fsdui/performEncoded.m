function encoded=performEncoded(request)
%PERFORMENCODED Plain process transport; engineering still runs only in perform.
request=fsd.project.decodeStorageGraph(request);
response=fsdui.perform(request);
encoded=fsd.project.encodeStorageGraph(response);
end
