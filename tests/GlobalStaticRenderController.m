classdef GlobalStaticRenderController < handle
    % Presentation-only fault injection: no solver or native project mutation.
    properties
        Project
        Status="Render retry test"
        Busy=false
        LastError=[]
        FailFinalStatus=false
    end
    properties(Dependent)
        LastValue
    end
    properties(Access=private)
        Reads=0
    end
    methods
        function obj=GlobalStaticRenderController(project)
            obj.Project=project;
        end
        function value=get.LastValue(obj)
            obj.Reads=obj.Reads+1;
            if obj.FailFinalStatus && obj.Reads==2
                error('fsd:test:TransientRender','Injected failure in final status presentation.');
            end
            value=[];
        end
    end
end
