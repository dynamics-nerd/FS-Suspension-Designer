# Application UI — v0.18 Guided Design

Launch from the repository: `app = launchFSSuspensionDesigner;`.
Edit with `appdesigner('app/FSSuspensionDesigner.m')` in MATLAB R2026b.
Keep the App Designer-generated XML companion. The native shell mounts dynamic
controls in `+fsdui/View.m`; `Controller.m` owns session and worker operations.
Callbacks collect presentation input and delegate engineering to public `fsd`
APIs. See [the complete guide](../docs/guided-design-interface.md).

