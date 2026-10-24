function value=globalStaticConfiguration(mode,input,previous)
%GLOBALSTATICCONFIGURATION Presentation-only mm/degree boundary, no engineering.
if nargin<3, previous=[]; end
ids=["FL","FR","RL","RR"];
controlNames=["Gravity [m/s2]","Gravity provenance","Gravity note","Operating configuration", ...
    "Contact policy","Contact provenance","Contact note","Mass approximation", ...
    "Unsprung position assumption","Road Z [mm]"];
optionNames=["forceTolerance_N","momentTolerance_Nm","positionTolerance_m","angleTolerance_rad", ...
    "stabilityTolerance_J","maxIterations","maxLineSearchSteps","selection","conditioningThreshold"];
if string(mode)=="ROWS"
    rows=struct('controls',{[cellstr(controlNames(:)),repmat({''},10,1)]}, ...
        'tires',{[cellstr(ids(:)),repmat({''},4,4)]},'paths',{[cellstr(ids(:)),repmat({''},4,1)]}, ...
        'coordinates',{[cellstr(["h [mm]";"pitch [deg]";"roll [deg]";"zFL [mm]";"zFR [mm]";"zRL [mm]";"zRR [mm]"]),repmat({''},7,3)]}, ...
        'guesses',{repmat({''},7,1)},'options',{[cellstr(optionNames(:)),repmat({''},9,1)]}, ...
        'contacts',{[cellstr(ids(:)),repmat({''},4,3)]},'heights',{cell(0,4)});
    if isempty(input), value=rows; return; end
    d=input.definition; vo=d.plan.vehicleOptions; so=d.plan.systemOptions;
    rows.controls(:,2)={vo.gravity_mps2;char(vo.gravitySourceKind);char(vo.gravitySourceNote); ...
        char(vo.operatingConfiguration);char(vo.contactPolicy);char(vo.contactSourceKind);char(vo.contactSourceNote); ...
        char(so.massApproximation);char(so.unsprungPositionAssumption);so.roadHeight_m*1000};
    factors=[1000;180/pi;180/pi;ones(4,1)*1000];
    rows.coordinates(:,2:4)=num2cell([d.options.bounds.*factors,d.options.coordinateScales.*factors]);
    rows.guesses=num2cell(d.plan.initialGuesses.*factors);
    for k=1:4
        t=[]; if isfield(d.inputs,'tires'), t=d.inputs.tires{k}; end
        % A valid project may retain a pending native tire at any corner.
        % Keep its presentation fields blank; readiness owns the diagnosis.
        if ~isempty(t)
            rows.tires(k,2:5)={t.stiffness_N_per_m/1000,t.unloadedRadius_m*1000,char(t.sourceKind),char(t.sourceNote)};
        end
        rows.paths{k,2}=char(join(compose('%.17g',d.plan.cornerPlans.(ids(k)).travel_m*1000),' '));
    end
    for k=1:numel(optionNames)
        if isfield(d.options,optionNames(k))
            v=d.options.(optionNames(k)); if isstring(v), v=char(v); end
            rows.options{k,2}=v;
        end
    end
    if isfield(vo,'contactPoints_m') && ~isempty(vo.contactPoints_m), rows.contacts(:,2:4)=num2cell(vo.contactPoints_m*1000); end
    if isfield(so,'rideHeightPointsBody_m')
        rows.heights=[cellstr(so.rideHeightPointIds),num2cell(so.rideHeightPointsBody_m*1000)];
    end
    value=rows; return;
end
assert(string(mode)=="DEFINITION",'fsd:ui:GlobalInput','Unknown table conversion.');
r=input;
if isempty(previous)
    d=struct('id',"UI_GLOBAL_STATIC",'engine',"GLOBAL_STATIC",'scope',fsd.model.designScope('VEHICLE','VEHICLE'), ...
        'plan',struct(),'inputs',struct(),'options',struct());
    vo=struct(); so=struct();
else
    d=previous.definition; vo=d.plan.vehicleOptions; so=d.plan.systemOptions;
end
v=r.controls(:,2);
vo.gravity_mps2=scalar(v{1},'Gravity'); vo.gravitySourceKind=string(v{2}); vo.gravitySourceNote=string(v{3});
vo.operatingConfiguration=string(v{4}); vo.contactPolicy=string(v{5});
vo.contactSourceKind=string(v{6}); vo.contactSourceNote=string(v{7});
vo.contactPoints_m=[];
if vo.contactPolicy=="EXPLICIT", vo.contactPoints_m=matrix(r.contacts(:,2:4))/1000; end
so.massApproximation=string(v{8}); so.unsprungPositionAssumption=string(v{9}); so.roadHeight_m=scalar(v{10},'Road Z [mm]')/1000;
so.rideHeightPointsBody_m=zeros(0,3); so.rideHeightPointIds=strings(0,1);
if ~isempty(r.heights)
    so.rideHeightPointIds=string(r.heights(:,1)); so.rideHeightPointsBody_m=matrix(r.heights(:,2:4))/1000;
end
tires=cell(4,1); plans=struct();
library=isfield(r,'sourceMode')&&string(r.sourceMode)=="LIBRARY_ASSIGNMENTS";
for k=1:4
    assert(string(r.tires{k,1})==ids(k) && string(r.paths{k,1})==ids(k),'fsd:ui:GlobalInput','Corner order changed.');
    if ~library
    tires{k}=fsd.model.createVerticalTireModel(struct('cornerId',ids(k),'modelType',"LINEAR_VERTICAL_UNILATERAL", ...
        'stiffness',scalar(r.tires{k,2},ids(k)+" tire stiffness [N/mm]"), ...
        'unloadedRadius',scalar(r.tires{k,3},ids(k)+" unloaded radius [mm]"), ...
        'sourceKind',string(r.tires{k,4}),'sourceNote',string(r.tires{k,5})),struct('length',"mm",'stiffness',"N/mm"));
    end
    plan=struct(); if ~isempty(previous), plan=d.plan.cornerPlans.(ids(k)); end
    plan.travel_m=fsdui.numberList(r.paths{k,2})/1000;
    assert(~isempty(plan.travel_m),'fsd:ui:GlobalInput','Explicit wheel travel samples required for each corner.');
    % GLOBAL_STATIC means prescribed rest, not a missing operating velocity.
    plan.wheelVelocity_m_per_s=0; plans.(ids(k))=plan;
end
factors=[1000;180/pi;180/pi;ones(4,1)*1000];
d.options.bounds=matrix(r.coordinates(:,2:3))./factors;
d.options.coordinateScales=matrix(r.coordinates(:,4))./factors;
for k=1:numel(optionNames)
    v=r.options{k,2};
    if strlength(string(v))==0
        if isfield(d.options,optionNames(k)), d.options=rmfield(d.options,optionNames(k)); end
    elseif optionNames(k)=="selection", d.options.selection=string(v);
    else, d.options.(optionNames(k))=scalar(v,optionNames(k));
    end
end
d.options=fsd.analysis.globalStaticSolverSettings(d.options);
if library, d.inputs=struct('tireSource',"LIBRARY_ASSIGNMENTS"); else, d.inputs=struct('tires',{tires}); end
d.plan=struct('vehicleOptions',vo,'systemOptions',so,'cornerPlans',plans,'initialGuesses',matrix(r.guesses)./factors);
value=d;
end
function v=scalar(v,label)
if nargin<2, label="Value"; end
if ~isnumeric(v), v=str2double(string(v)); end
assert(isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v),'fsd:ui:GlobalInput', ...
    '%s: supply a finite numeric value; blank is missing.',string(label));
v=double(v);
end
function a=matrix(rows)
a=zeros(size(rows)); for k=1:numel(rows), a(k)=scalar(rows{k}); end
end
