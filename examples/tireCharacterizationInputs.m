function [definition,states,request]=tireCharacterizationInputs()
%TIRECHARACTERIZATIONINPUTS Explicit synthetic software case, never FS advice.
params=struct('Fz0_N',500,'mu0',1,'Calpha_N_per_rad',8000,'Ckappa_N',10000, ...
    'Cgamma_N_per_rad',500,'n',.8,'pAlpha',.9,'pKappa',.85,'qGamma_per_rad2',1);
geometry=struct('unloadedRadius_m',.25,'width_m',.18,'rimRadius_m',.13);
vertical=struct('stiffness_N_per_m',100000); provenance=struct();
for name=[string(fieldnames(params));string(fieldnames(geometry));string(fieldnames(vertical))]'
    provenance.(name)=struct('sourceKind',"ASSUMED",'sourceNote',"Synthetic software benchmark; not measured FS tire data");
end
force=struct('family',"DUGOFF_REDUCED_1",'parameters',params, ...
    'domain',struct('Fz_N',[0,2000],'alpha_rad',[-.4,.4],'kappa',[-.8,.8],'gamma_rad',[-.15,.15]), ...
    'capacityLoad',"POWER",'lateralLoad',"POWER",'longitudinalLoad',"POWER", ...
    'camberThrust',"LINEAR_CONSTANT",'camberCapacity',"QUADRATIC");
definition=struct('id',"SYNTHETIC_TIRE",'name',"Synthetic software benchmark",'level',"GENERIC", ...
    'geometry',geometry,'vertical',vertical,'force',force,'provenance',provenance,'evidence',"ASSUMPTION_BASED");
states=struct('Fz_N',500,'alpha_rad',linspace(-.3,.3,121)','kappa',0,'gamma_rad',0);
request=struct('channels',["Fx";"Fy"],'domainPolicy',"MARK");
end
