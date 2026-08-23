# REG-20260817-2752: C34L prerequisite-proof attempt binding omission

## Truthful event

Primary end-to-end review after the first dual-host green transaction suites
found that lifecycle evidence validates `attempt`, and postbuild recovery
validates the selected attempt, but prerequisite gate proofs and retained
lifecycle proof records do not. The transition exposes an `Attempt` parameter
yet never compares it with `proof.attempt`; the wrapper proof helper does not
pass the selected preflight attempt to the future candidate gate or transition;
and retained-evidence history matching does not require record ticket/attempt
parity. A proof from another attempt could therefore be accepted if all other
preimage fields happened to match.

This was found by source review after fixture qualification. No real C34L
state, aggregate, source seal, cycle, AAB, Google Play, device, credential,
secret, deployment, or external state changed.

## Root cause

The final proof schema was propagated for ticket, hashes, counts and authorities
but its attempt dimension was implemented only in produced evidence and
recovery, not across the candidate-gate caller, transition, journal, and
retained history interfaces.

## Prevention

- Require `attempt` in every candidate-gate proof and compare it exactly with
  the transition `-Attempt` value.
- Pass the selected preflight attempt through wrapper proof generation and
  every transition call; pass explicit attempt 1 in the founder launcher.
- Persist ticket and attempt in lifecycle proof records and transaction
  journals, and require retained evidence to match both.
- Add wrong-attempt negatives on both PowerShell hosts before qualification.

## Candidate consequence

C34L remains selection-only. The previous green suites are incomplete until
attempt binding passes end to end; no real release action is authorized.
