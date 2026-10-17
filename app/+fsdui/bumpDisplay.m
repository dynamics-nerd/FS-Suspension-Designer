function display = bumpDisplay(result)
%BUMPDISPLAY Read stored evidence and delegate quality to the audited adapter.
g=result.prepared.resources.geometries{1}; payload=result.nativePayload;
quality=fsd.synthesis.bumpSweepQuality(g,payload.sweep);
display=struct('analysis',payload.analysis,'quality',quality,'rows',{cell(0,8)});
rows=cell(numel(payload.sweep.results),8);
for j=1:size(rows,1)
    rows(j,:)={char(result.id),char(g.cornerId),j,payload.sweep.requestedWheelTravel_m(j), ...
        payload.sweep.converged(j),char(payload.analysis.status(j)),quality.reliable(j),quality.rcond(j)};
end
display.rows=rows;
end
