function drawGeometry(geometry,axesHandle,style)
%DRAWGEOMETRY Delegate members/points to native plot; add a display-only wheel ring.
handles=fsd.geometry.plotDoubleWishboneGeometry(geometry,axesHandle);
if nargin<3, style="STANDARD"; end
set(handles.labels,'Visible','off'); % Dense labels obscure the pair; identify via table/data tips.
handles.hardpoints.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Point ID',geometry.hardpoints.ids);
wasHeld=ishold(axesHandle); hold(axesHandle,'on');
cleanup=onCleanup(@()hold(axesHandle,matlab.lang.OnOffSwitchState(wasHeld)));
center=fsd.model.getPoint(geometry,geometry.cornerId+"_WHEEL_CENTER");
basis=null(geometry.wheel.wheelAxis(:)');
% 65 display samples close the ideal circle; not a physical or numerical tolerance.
theta=linspace(0,2*pi,65);
contact=fsd.analysis.geometricWheelContact(geometry);
ring=center'+contact.geometricRadius_m*basis*[cos(theta);sin(theta)];
wheelRing=plot3(axesHandle,ring(1,:),ring(2,:),ring(3,:),'Color',[.25 .32 .40],'LineWidth',1.4);
if style=="SEED"
    % Rendering convention only: distinguish coincident seed/candidate overlays.
    set([handles.uca;handles.lca;handles.tieRod;handles.upright;handles.wheelReference;handles.wheelAxis;wheelRing], ...
        'Color',[.58 .60 .63],'LineStyle','--');
    handles.hardpoints.MarkerFaceColor=[.58 .60 .63];
end
set(axesHandle,'Color',[1 1 1],'XColor',[.1 .15 .2],'YColor',[.1 .15 .2],'ZColor',[.1 .15 .2]);
end
