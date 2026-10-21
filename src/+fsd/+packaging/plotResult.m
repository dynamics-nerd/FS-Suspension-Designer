function handles=plotResult(result,axesHandle,sampleIndex,checkIndex)
%PLOTRESULT Render only stored resolved volumes/points; never invent a pose.
fsd.packaging.validateResult(result);
assert(isgraphics(axesHandle,'axes') && isscalar(sampleIndex) && sampleIndex>=1 && ...
    sampleIndex<=numel(result.states) && fix(sampleIndex)==sampleIndex,'fsd:packaging:InvalidPlot','Valid axes/sample required.');
if nargin<4, checkIndex=NaN; end
ax=axesHandle; cla(ax); hold(ax,'on'); state=result.states{sampleIndex}; selected=strings(0,1); pairStatus="";
handles=struct('volumes',{{}},'skeleton',gobjects(0),'witnesses',gobjects(0),'sampleIndex',sampleIndex);
if isfinite(checkIndex)
    assert(checkIndex>=1 && checkIndex<=numel(result.checks) && fix(checkIndex)==checkIndex, ...
        'fsd:packaging:InvalidPlot','Selected check does not exist.');
    check=result.checks{checkIndex};
    assert(check.sampleIndex==sampleIndex,'fsd:packaging:InvalidPlot','Check and selected sample differ.');
    selected=[check.firstVolume;check.secondVolume]; pairStatus=check.status;
    if all(isfinite(check.witnesses_m),'all')
        w=check.witnesses_m; handles.witnesses=plot3(ax,w(:,1),w(:,2),w(:,3),'k.-','LineWidth',2,'MarkerSize',16);
    end
end
if state.valid
    members=result.geometry.connectivity;
    for j=1:size(members.pointIds,1)
        ids=members.pointIds(j,:); points=zeros(numel(ids),3);
        for k=1:numel(ids), points(k,:)=state.points.xyz_m(state.points.ids==ids(k),:); end
        handles.skeleton(end+1)=plot3(ax,points(:,1),points(:,2),points(:,3),'--','Color',[.4 .4 .4]);
    end
end
for j=1:numel(state.volumes)
    volume=state.volumes{j}; if isempty(volume), continue; end
    d=volume.definitionSI; colour=[.35 .55 .78]; alpha=.28;
    if d.binding.mode=="FIXED" && d.componentType=="OBSTACLE", colour=[.4 .4 .4]; end
    if d.role=="FREE_REGION", colour=[.2 .65 .4]; alpha=.08; end
    if ismember(d.id,selected)
        colour=[.85 .22 .12];
        if pairStatus=="CLEAR_SAMPLED", colour=[.12 .6 .25]; end
        if ismember(pairStatus,["INCOMPLETE","NOT_EVALUATED","EXEMPT_CONTACT"]), colour=[.65 .45 .1]; end
        alpha=.55;
    end
    if isempty(d.dimensions) || d.shape=="CYLINDER"
        p=d.transform(1:3,4);
        text(ax,p(1),p(2),p(3),d.id+" — NOT RENDERED / incomplete or unsupported",'Interpreter','none','Color',[.55 .35 .1]);
        continue;
    end
    handles.volumes{end+1,1}=drawVolume(ax,d,colour,alpha);
end
hold(ax,'off'); axis(ax,'equal'); grid(ax,'on'); view(ax,3);
xlabel(ax,'X rearward [m]'); ylabel(ax,'Y rightward [m]'); zlabel(ax,'Z upward [m]');
title(ax,[result.status;result.plan.mode+" sample "+sampleIndex],'Interpreter','none','FontSize',10);
if ~state.valid
    title(ax,["INCOMPLETE — source pose unavailable";"No mobile pose invented"],'FontSize',10);
end
ax.UserData=struct('sampleIndex',sampleIndex,'checkIndex',checkIndex,'pairStatus',pairStatus);
end

function handle=drawVolume(ax,d,colour,alpha)
T=d.transform;
if ismember(d.shape,["AABB","OBB"])
    signs=[-1 -1 -1;1 -1 -1;-1 1 -1;1 1 -1;-1 -1 1;1 -1 1;-1 1 1;1 1 1];
    points=(signs.*d.dimensions/2)*T(1:3,1:3)'+T(1:3,4)';
    faces=[1 2 4 3;5 6 8 7;1 2 6 5;3 4 8 7;1 3 7 5;2 4 8 6];
    handle=patch(ax,'Vertices',points,'Faces',faces,'FaceColor',colour,'FaceAlpha',alpha,'EdgeColor',colour);
else
    % Display tessellation only: 24 azimuth subdivisions, 8 per hemisphere.
    azimuth=linspace(0,2*pi,25)'; phi=[linspace(-pi/2,0,9),linspace(0,pi/2,9)];
    radius=d.dimensions(1); half=0; if d.shape=="CAPSULE", half=d.dimensions(2)/2; end
    z=[-half+radius*sin(phi(1:9)),half+radius*sin(phi(10:18))];
    x=cos(azimuth)*(radius*cos(phi)); y=sin(azimuth)*(radius*cos(phi)); zz=ones(25,1)*z;
    points=[x(:),y(:),zz(:)]*T(1:3,1:3)'+T(1:3,4)';
    handle=surf(ax,reshape(points(:,1),size(x)),reshape(points(:,2),size(x)),reshape(points(:,3),size(x)), ...
        'FaceColor',colour,'FaceAlpha',alpha,'EdgeColor','none');
end
handle.DisplayName=char(d.id); handle.UserData=struct('volumeId',d.id,'componentId',d.componentId,'fidelity',d.fidelity);
end
