# C24H cycle 1 gate-wrapper argument-splat rejection

Date: 2026-08-09
Regression: `REG-20260809-749-C24H-QUALIFIER-GATE-WRAPPER-ARGUMENT-ARRAY-SPLATTED-POSITIONALLY`

## Passing partial evidence

- 78 affected format owners checked, zero changes required.
- Complete Flutter analysis passed with no issues.
- The merged affected plus protected suite passed 888 tests with 35 retained
  visual-capture skips and zero test failures.

## Rejection

The qualifier then rejected before the first of 18 gates. Its wrapper call
splatted `-RepositoryRoot` and the repository path into separate positional
function parameters instead of binding them to the wrapper's `-Arguments`
array. No final fingerprint comparison or evidence JSON was produced, so this
run is not a qualifying cycle. Two entirely new complete cycles remain
required after correction.

Every wrapper call now binds `-RelativePath` explicitly and passes optional
tokens through the named `-Arguments` array.
