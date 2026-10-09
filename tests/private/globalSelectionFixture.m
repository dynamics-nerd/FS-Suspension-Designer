function [s, o, seeds] = globalSelectionFixture(category)
%GLOBALSELECTIONFIXTURE Known ideal paths for selection, not physical linkage claims.
% All SI parameters inherit the documented globalStaticFixture benchmark.
switch category
    case "NON_RESTORING_STATIONARY_POINT"
        [s,o] = globalStaticFixture(repmat(.05,4,1),zeros(4,1),[1,0,.3],100000,-10);
        seeds = [-.005;zeros(6,1)];
    case "MARGINAL_OR_DEGENERATE"
        [s,o,sources,tires,v,lc] = globalStaticFixture([0;.05;.05;.05],zeros(4,1),[4/3,.65/3,.3]);
        z = sources{1}.mechanical.path.achievedWheelTravel_m;
        sources{1}.mechanical = fsd.analysis.analyzePrescribedSpringDamperPath( ...
            sources{1}.springDamper,z,-.5*z,0,struct("length","m","velocity","m/s"));
        s = fsd.model.createGlobalStaticSystem(v,lc,sources,tires,s.options);
        seeds = [-.04;0;0;.048;repmat(1/30,3,1)];
    case "STABILITY_NOT_EVALUABLE"
        [s,o,sources,tires,v,lc] = globalStaticFixture;
        for i = 1:4
            model = sources{i}.springDamper;
            % Exact nominal seat separation: free length .2 minus preload .05.
            model.spring.solidHeight_m = .15;
            model.identity = fsd.model.springDamperIdentity(model);
            z = sources{i}.mechanical.path.achievedWheelTravel_m;
            sources{i}.springDamper = model;
            sources{i}.mechanical = fsd.analysis.analyzePrescribedSpringDamperPath( ...
                model,z,.5*z,0,struct("length","m","velocity","m/s"));
        end
        s = fsd.model.createGlobalStaticSystem(v,lc,sources,tires,s.options);
        seeds = [-.005;zeros(6,1)];
    case "DOUBLE_WELL"
        [s,o,sources,tires,v,lc] = globalStaticFixture;
        % Explicit synthetic energy: Us=25+500*z+K*P(z), in J, where
        % P'= (z+a)*(z-r)*(z-a). Symmetric chassis roots lie near +/-a;
        % these are minima, and U(+a)-U(-a)=4*(4/3)*K*r*a^3 > 0.
        % Derive compression from the existing Us=.5*ks*(preload+c)^2 law.
        % a/r/K and the grid define a test function, NOT engineering defaults.
        a = .015; r = .01; K = 1e7;
        z = (-.03005:.0001:.03005)'; % +/-a lie inside smooth pp pieces
        P = z.^4/4-r*z.^3/3-a^2*z.^2/2+r*a^2*z;
        c = sqrt(2*(25+500*z+K*P)/20000)-.05;
        for i = 1:4
            sources{i}.mechanical = fsd.analysis.analyzePrescribedSpringDamperPath( ...
                sources{i}.springDamper,z,c,0,struct("length","m","velocity","m/s"));
            nominal = fsd.model.getPoint(sources{i}.geometry,sources{i}.geometry.cornerId+"_WHEEL_CENTER");
            sources{i}.idealWheelCenterPath_m = nominal+z*[0,0,1];
            sources{i}.sourceNote = "ASSUMED double-well energy contract fixture; no linkage feasibility claim";
        end
        s = fsd.model.createGlobalStaticSystem(v,lc,sources,tires,s.options);
        seeds = [[-.005-a;0;0;repmat(a,4,1)],[-.005+a;0;0;repmat(-a,4,1)]];
    otherwise
        assert(category == "LOCAL_STABLE_MINIMUM","Unknown selection fixture.");
        [s,o] = globalStaticFixture;
        seeds = [-.005;zeros(6,1)];
end
o.selection = "LOWEST_ENERGY_STABLE";
end
