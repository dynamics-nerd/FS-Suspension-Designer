function prepared=prepareAntiRollBar(bar,sources)
%PREPAREANTIROLLBAR Operation-local serializable mechanical preparation.
if nargin<2, sources={}; end
fsd.model.validateAntiRollBar(bar); r=fsd.model.antiRollBarReadiness(bar,'MECHANICAL');
prepared=struct('schemaVersion',"0.23.0",'kind',"PreparedAntiRollBar",'bar',bar, ...
    'sources',{sources},'paths',{{}},'stiffness',[],'readiness',r,'identity',bar.identity);
if bar.definition.representation=="COAXIAL_TORSION"
    prepared.stiffness=fsd.analysis.antiRollBarStiffness(bar);
    if ~iscell(sources)||numel(sources)~=2
        prepared.readiness.status="MISSING_DATA";
        prepared.readiness.missing=unique([r.missing;"SOURCES:ARB_DRIVER_PATHS"]); return;
    end
    geometryReady=fsd.model.antiRollBarReadiness(bar,'GEOMETRY');
    if geometryReady.status~="READY"
        prepared.readiness.status=geometryReady.status;
        prepared.readiness.missing=unique([r.missing;geometryReady.missing]); return;
    end
    prepared.paths=cell(2,1);
    for side=1:2, prepared.paths{side}=arbDriverPathCore(bar,side,sources{side}); end
    if any(cellfun(@(v)isempty(v.segments),prepared.paths))
        prepared.readiness.status="MISSING_DATA";
        prepared.readiness.missing=unique([r.missing;"SOURCES:CONNECTED_ARB_DRIVER_PATH"]);
    end
end
end
