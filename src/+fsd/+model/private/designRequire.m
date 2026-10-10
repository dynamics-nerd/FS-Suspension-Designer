function designRequire(condition, message)
%DESIGNREQUIRE Common definition-boundary error, without engineering defaults.
if ~isscalar(condition) || ~condition
    error("fsd:model:InvalidDesignDefinition","%s",message);
end
end
