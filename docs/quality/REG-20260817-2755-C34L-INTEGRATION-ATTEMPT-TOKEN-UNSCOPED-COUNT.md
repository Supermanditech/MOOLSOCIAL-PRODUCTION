# REG-20260817-2755: C34L integration unscoped attempt-token count

## Truthful event

Before running the updated integration gate, bounded source readback found that
its new assertion expected five occurrences of `-Attempt $preflightAttempt`
across the complete wrapper, while the wrapper truthfully contains eight. Five
belong to the new proof/transition interface, and three existing terminal-result
calls use the same token. The unscoped raw count would therefore create a false
static rejection. The integration sub-agent stopped before patch, gate,
launcher, build, or any other qualification action.

No real C34L state, aggregate, source seal, cycle, AAB, Google Play, device,
credential, secret, deployment, or external state changed.

## Root cause

The static gate counted a shared token globally while reasoning about a
specific set of caller regions.

## Prevention

- Assert attempt propagation inside each uniquely delimited proof and
  transition caller region.
- Treat the complete wrapper token count only as an inventory diagnostic, not
  as semantic caller-coverage evidence.
- Cover helper, gate, transition, terminal-evidence, and launcher call sites
  independently before dual-host qualification.

## Candidate consequence

C34L remains selection-only. The prior integration qualification is superseded
until the scoped attempt-binding assertions pass on both hosts.
