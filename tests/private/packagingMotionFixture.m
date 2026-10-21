function [definition,geometry]=packagingMotionFixture(obstacleTravel_m)
%PACKAGINGMOTIONFIXTURE Synthetic exact circular-translation case, not FS data.
axle=translationAxleFixture(); geometry=axle.leftGeometry;
centre=fsd.model.getPoint(geometry,'FL_WHEEL_CENTER');
moving=packagingVolumeFixture('UPRIGHT_SOLID','SPHERE',.01,centre);
d=moving.definitionSI; d.componentType="UPRIGHT";
d.binding=struct('mode',"UPRIGHT",'cornerId',"FL",'pointIds',strings(0,1));
moving=fsd.packaging.createVolume(d,'m');
% Independent circular oracle from the original 0.3m parallelogram fixture.
delta=[0,.3-sqrt(.3^2-obstacleTravel_m^2),obstacleTravel_m];
fixed=packagingVolumeFixture('OBSTACLE','SPHERE',.01,centre+delta);
d=fixed.definitionSI; d.componentType="OBSTACLE"; fixed=fsd.packaging.createVolume(d,'m');
pair=struct('id',"UPRIGHT_OBSTACLE",'first',"UPRIGHT_SOLID",'second',"OBSTACLE", ...
    'requiredClearance_m',.005,'exception',[]);
definition=fsd.packaging.createDefinition(struct('id',"SOFTWARE_CASE",'volumes',{{moving;fixed}},'pairs',{{pair}},'regions',{{}}));
end
