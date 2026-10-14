function project = projectWorkflowFixture(engine)
%PROJECTWORKFLOWFIXTURE Reuse historical, explicit native fixture inputs.
if nargin<1, engine="BUMP"; end
[concept,physical]=conceptWorkflowFixture(); resources=struct(); scope=fsd.model.designScope('CORNER','FL');
options=struct(); spec=[]; plan=struct(); inputs=struct(); links=strings(0,2);
switch engine
    case {"ACTUATION_SYNTHESIS","BUMP","ACTUATION","MECHANICAL","STATIC_GEOMETRY"}
        [s,options]=actuationSynthesisFixture();
        resources=struct('geometries',{{s.seed}},'actuations',{{s.seedActuation}},'mechanicals',{{s.seedMechanical}});
        if engine=="ACTUATION_SYNTHESIS", spec=s.specification; plan=s.plan;
        elseif engine=="STATIC_GEOMETRY", options=struct();
        else
            options=struct(); plan=struct('travel_m',[-.01;0;.01]);
            if engine=="MECHANICAL", plan.wheelVelocity_m_per_s=0; end
        end
    case "CORNER_SYNTHESIS"
        [s,options]=synthesisFixture(); resources.geometries={s.seed}; plan=s.plan; spec=s.specification;
    case {"AXLE_SYNTHESIS","ROLL"}
        [s,options]=axleSynthesisFixture(true); resources.geometries={s.seedAxle.leftGeometry;s.seedAxle.rightGeometry};
        scope=fsd.model.designScope('AXLE','FRONT');
        if engine=="AXLE_SYNTHESIS", plan=s.plan; spec=s.specification;
        else, plan=struct('angles_rad',[-.01;0;.01],'axleHeave_m',0); options=struct(); end
    case {"STEERING_SYNTHESIS","RACK"}
        [s,options]=steeringSynthesisFixture(); resources.geometries={s.seedAxle.leftGeometry;s.seedAxle.rightGeometry}; resources.steerings={s.seedSteering};
        scope=fsd.model.designScope('AXLE','FRONT');
        if engine=="STEERING_SYNTHESIS", plan=s.plan; spec=s.specification;
        else, plan=struct('travel_m',[-.005;0;.005],'wheelTravel_m',[0,0]); options=struct(); end
    case "STATIC_LOADS", scope=fsd.model.designScope('VEHICLE','VEHICLE'); plan=physical;
end
scenario=fsd.project.createEngineeringScenario(struct('id',"SCENARIO",'engine',engine,'scope',scope, ...
    'plan',plan,'options',options,'specification',spec,'inputs',inputs,'symmetryLinks',links));
project=fsd.project.createEngineeringProject(struct('concept',concept,'resources',resources,'scenarios',{{scenario}}));
end
