# UAW AAB C30Y static helper R collided with Invoke-History

Date: 2026-08-15
Regression: `REG-20260815-2204-AAB-C30Y-STATIC-HELPER-R-COLLIDED-WITH-INVOKE-HISTORY`
Status: registered before retry

## Finding

The post-REG-2203 cycle-1 attempt-05 wrapper shortened its record helper to
`R`. PowerShell resolved that command to the built-in `Invoke-History` alias,
which has precedence over the function, and the wrapper failed before the
first child gate ran. The attempt has zero static-gate evidence.

No build, upload, activation, install, device, provider or credential action
occurred.

## Prevention

- Reuse the already-passed `Write-Record` and `Invoke-Gate` helper names
  verbatim.
- Never introduce one-letter or generic command helpers in release wrappers.
- Do not compact or rename a qualification wrapper after the prior form has
  passed.
- Use new cycle attempt stems after registration.

## Resolution

Both fresh cycles used the exact proven `Write-Record` and `Invoke-Gate`
helpers, passed every static child gate, completed all executable stages and
passed both-host evidence binding.

- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-post-fix5-cycle-01-attempt-06-summary.json`
- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-post-fix5-cycle-02-attempt-04-summary.json`
