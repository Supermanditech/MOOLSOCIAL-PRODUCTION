# REG-20260817-2750: C34L recovery pretransition proof-binding paradox

## Truthful event

Primary review of the new C34L postbuild-recovery owner found that it requires
`state.phaseGateProofs.buildSucceeded.path/sha256` while the candidate is still
in the interrupted build-in-progress preimage. The agreed candidate gate is
non-mutating and writes a fresh immutable proof file. The lifecycle transition
can persist that proof binding only after it commits. Therefore, at the exact
crash boundary recovery is intended to handle—proof written, transition not
yet committed—the state-side binding cannot lawfully exist.

The recovery owner had only been parsed on both PowerShell hosts; it had not
executed against a real or fixture candidate. No real C34L state, aggregate,
source seal, cycle, AAB, Google Play, device, credential, secret, deployment,
or external state changed.

## Root cause

Recovery reused a post-transition state binding as the source of a
pre-transition proof instead of deriving the exact immutable attempt proof
owner and validating its bytes directly against the current detailed and
aggregate preimage.

## Prevention

- Derive the exact attempt-scoped `11b-build-succeeded-proof` path from the
  approved evidence root and selected attempt.
- Hash and validate that immutable proof directly against the current detailed
  and aggregate bytes, ticket, attempt, transition, phase, all eight counts,
  and all four authorities.
- Reject any alternate proof path, multiple attempt proof owners, or reliance
  on a state binding that is only created by the missing transition.
- Add a fixture-only recovery audit that exercises this exact crash boundary on
  both required hosts without adding a production bypass switch.

## Candidate consequence

C34L remains selection-only. Recovery is not qualified and no real state or
release action is authorized.
