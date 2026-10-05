# Testing strategy

Development follows this gate:

> Engineering change → Unit test → Known case → Validation → Merge

`TestRepositoryFoundation.m` currently verifies only what is implemented: that the `fsd` namespace is reachable and that the required architectural documents exist. It intentionally does not pretend to test suspension behavior before that behavior exists.

Run all tests from the repository root with:

```matlab
results = runProjectTests;
```

## First v0.1 test set

Implement these alongside the Static Double Wishbone Geometry code:

1. A valid hardpoint can be created with a canonical ID, one allowed corner and one real finite `1x3` position in metres.
2. Row, column, short, long and nonnumeric XYZ inputs are handled according to one documented API contract; do not silently reshape ambiguous input.
3. Empty, malformed, unknown and duplicate hardpoint IDs are rejected with stable error identifiers.
4. `NaN`, `Inf`, `-Inf` and complex coordinates are rejected.
5. A complete v0.1 corner contains every required hardpoint exactly once.
6. UCA forward/aft chassis pivots, LCA forward/aft chassis pivots, UBJ/LBJ and wheel-center/contact-patch pairs are not coincident under the approved tolerance policy.
7. A documented known geometry preserves distances and connectivity when mirrored left/right.
8. Mirroring twice returns the original coordinates within the approved tolerance.
9. A plotting test verifies returned graphics objects and connectivity without relying on pixel comparisons.

Numerical expected values must come from a documented analytic or independently validated case. Symmetry tests must use the reflection rules in `docs/coordinate-system.md`; the side-normalization matrix is not a rotation.

Referencia: [MathWorks — Write Unit Tests](https://www.mathworks.com/help/matlab/write-unit-tests.html).
