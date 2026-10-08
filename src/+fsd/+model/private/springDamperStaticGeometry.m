function derived = springDamperStaticGeometry(model)
%SPRINGDAMPERSTATICGEOMETRY Seats move with damper ends; offset may be signed.
id = model.actuationIdentity;
length0 = norm(id.rockerDamperPointStatic_m-id.damperChassisPoint_m);
seats0 = model.spring.freeLength_m-model.spring.preloadCompression_m;
derived = struct("damperStaticLength_m",length0, ...
    "springSeatSeparationStatic_m",seats0,"springSeatOffset_m",seats0-length0);
end
