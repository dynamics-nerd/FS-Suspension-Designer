function figures = plotGlobalStaticEquilibrium(system, result)
%PLOTGLOBALSTATICEQUILIBRIUM Reduced vertical tire view and prescribed energy slices.
fsd.analysis.validateGlobalStaticEquilibrium(result,system);
if ~isfinite(result.selectedIndex)
    error("fsd:analysis:InvalidGlobalStaticEquilibrium", ...
        "No alternative selected under %s; stationary alternatives retained, no selected pose to plot.", ...
        result.solverOptions.selection);
end
solution = result.alternatives{result.selectedIndex}; state = solution.state;
p = fsd.analysis.prepareGlobalStaticSystem(system);
figures = gobjects(3,1);
figures(1) = figure("Name","Global static pose — sampled paths"); ax = axes(figures(1)); hold(ax,"on");
body = p.nominalWheelCentersBody_m;
body = (state.rotationMatrix*body')'+[0,0,state.heave_m];
order = [1,2,4,3,1]; plot3(ax,body(order,1),body(order,2),body(order,3),"k--");
ground = system.options.roadHeight_m;
for i = 1:4
    c = state.corners{i}; w = c.wheelCenterWorld_m;
    color = [0,.5,0]; if c.tire.contactStatus ~= "IN_CONTACT", color = [.8,0,0]; end
    plot3(ax,w(1),w(2),w(3),"o","Color",color);
    plot3(ax,[w(1),w(1)],[w(2),w(2)],[w(3),w(3)-c.tire.loadedRadius_m],"-","Color",color);
    text(ax,w(1),w(2),w(3)," "+c.cornerId);
end
x = [min(body(:,1))-.2,max(body(:,1))+.2]; y = [min(body(:,2))-.2,max(body(:,2))+.2];
patch(ax,x([1,2,2,1]),y([1,1,2,2]),repmat(ground,1,4),[.7,.7,.7],"FaceAlpha",.2);
axis(ax,"equal"); grid(ax,"on"); view(ax,3); xlabel(ax,"X rear [m]"); ylabel(ax,"Y right [m]"); zlabel(ax,"Z up [m]");
title(ax,"Dashed chassis reference; vertical tire surrogate (not camber-dependent contact)");
figures(2) = figure("Name","Global loads and residuals"); tiledlayout(figures(2),2,2);
ax = nexttile; bar(ax,[state.normalForces_N,p.referenceLoadsV09.cornerLoads_N]);
xticklabels(ax,system.cornerIds); ylabel(ax,"N"); title(ax,"Prediction / v0.9 reference (not imposed)");
ax = nexttile; values = cellfun(@(c) [c.spring.springCompression_m,c.tire.tireCompression_m],state.corners,"UniformOutput",false);
bar(ax,vertcat(values{:})); ylabel(ax,"Compression [m]"); xticklabels(ax,system.cornerIds);
ax = nexttile; hold(ax,"on");
for i = 1:numel(result.attempts), plot(ax,result.attempts{i}.diagnostics.scaledResidualHistory); end
ylabel(ax,"max |residual/budget|"); xlabel(ax,"Iteration"); title(ax,result.status,"Interpreter","none");
ax = nexttile; bar(ax,state.worldMomentResidual_Nm); ylabel(ax,"World moment residual [Nm]");
figures(3) = figure("Name","Prescribed energy slices — not re-equilibrated"); tiledlayout(figures(3),1,3);
labels = ["heave [m]","pitch [rad]","roll [rad]"];
for i = 1:3
    offsets = linspace(-1,1,41)*result.solverOptions.coordinateScales(i)/10; energy = nan(size(offsets));
    for j = 1:numel(offsets)
        q = state.q; q(i) = q(i)+offsets(j); a = globalStateCore(p,q); energy(j) = a.potentialEnergy_J;
    end
    ax = nexttile; plot(ax,offsets,energy); xlabel(ax,labels(i));
    ylabel(ax,"U [J]"); grid(ax,"on");
end
end
