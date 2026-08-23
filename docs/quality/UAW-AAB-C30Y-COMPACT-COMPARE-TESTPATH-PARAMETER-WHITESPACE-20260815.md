# UAW AAB C30Y compact compare Test-Path parameter whitespace

Date: 2026-08-15
Regression: `REG-20260815-2203-AAB-C30Y-COMPACT-COMPARE-TESTPATH-PARAMETER-WHITESPACE`
Status: registered before retry

## Finding

Both post-REG-2202 cycles completed and passed their dual-host evidence binders.
The later named-scalar comparison wrapper failed only when its compacted
`Test-Path` expression omitted whitespace before `-PathType`, producing an
invalid positional parameter error.

The comparison attempt is non-qualifying and preserved at:

- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-post-fix5-post-reg2202-two-cycle-substantive-compare.log`
- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-post-fix5-post-reg2202-two-cycle-substantive-compare.log.exit.txt`

No build, upload, activation, install, device, provider or credential action
occurred.

## Prevention

- Reuse the earlier proven uncompressed named-scalar comparison form.
- Resolve each `Test-Path -LiteralPath ... -PathType Leaf` result into a
  separate labeled boolean before comparison.
- Do not compact named-parameter boundaries in release evidence wrappers.
- Run two fresh versioned cycles after memory registration.

## Resolution

The previously passed uncompressed named-scalar form was reused. Each evidence
path's existence was calculated in a separate labeled boolean before
comparison. The post-REG-2204 cycle pair passed substantive equality.

- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-post-fix5-post-reg2204-two-cycle-substantive-compare.log`
