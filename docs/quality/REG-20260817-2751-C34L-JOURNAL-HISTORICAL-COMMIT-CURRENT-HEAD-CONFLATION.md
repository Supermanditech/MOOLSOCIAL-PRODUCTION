# REG-20260817-2751: C34L historical commit/current-head conflation

## Truthful event

After REG2749 and REG2750 were registered, the transaction stream corrected
the strict-mode journal schema and the implementation regression-memory gate
passed at 2721 entries and 1729 applicable lessons. The next PowerShell 7
lifecycle fixture completed one transition and then rejected the following
lawful transition with `committed transaction targets changed after journal
commit.` Reconciliation required every historical committed journal postimage
to equal the current detailed and aggregate files. Once the next transition
advances those files, the earlier committed postimage is necessarily no longer
the current head. The agent stopped without retry or correction.

The unique fixture was cleaned up. No real C34L state, aggregate, source seal,
cycle, AAB, Google Play, device, credential, secret, deployment, or external
state changed.

## Root cause

Journal reconciliation conflated immutable historical commit validation with
current-head validation instead of validating an ordered transaction chain.

## Prevention

- Sort terminal journals by the deterministic transaction sequence and require
  every committed postimage to equal the next transaction's preimage.
- Validate immutable fields and recorded hashes for every historical journal,
  but require current detailed and aggregate bytes to equal only the newest
  terminal journal's postimage.
- Fail closed on forks, gaps, duplicate sequence identities, or a newest
  nonterminal journal that cannot be deterministically reconciled.
- Exercise at least two lawful consecutive transitions plus every injected
  crash boundary on both required PowerShell hosts.

## Candidate consequence

C34L remains selection-only. The failure is zero lifecycle qualification
evidence and authorizes no real state creation or external action.
