# UAW-C33J FIX2 parent-gate stale HTTPS-only anchor

Date: 2026-08-15

Regression: `REG-20260815-2516-C33J-FIX2-PARENT-GATE-STALE-HTTPS-ONLY-ANCHOR`

## Finding

The first composed predecessor-gate replay stopped in the C33J parent checker
after the FIX2 implementation replaced the generic
`isQualifiedHttpsRuntimeEndpoint` call with the stricter
`isQualifiedEmailLinkRuntimeConfiguration` policy. The source was correctly
more restrictive, but the parent static anchor still required the superseded
helper spelling.

Because the parent and FIX1 gates were invoked in one fail-fast command, the
FIX1 gate was not executed and no FIX1 replay result was counted.

## Resolution rule

- Update the parent gate to bind the current email-link runtime policy and both
  of its inputs: continue URL and link domain.
- Preserve the historical C33J acceptance anchors; do not weaken them.
- Replay the parent, FIX1 and FIX2 gates as separate commands on both
  PowerShell hosts, counting only exit-zero results.
- Keep successor hardening and predecessor composition synchronized whenever a
  protected invariant changes.

No build, deployment, live email, Play or device authority is created by this
record.
