# REG2908 — C34M primary auth-queue selection property-level guess

## Incident

On 2026-08-18, the primary reviewer parsed the five new queued authentication ticket JSON owners but projected `selected`, `registeredForExecution`, and `candidateIdentityReserved` from a guessed nested `selection` object. The properties are not located at that guessed level, so the projection returned null and is not accepted as proof of inactive state.

## Impact

- The five JSON files parsed successfully, but the three null selection values from this projection are inadmissible review evidence.
- No ticket, active MVP selection, authority, runtime, provider, build, browser, Play, OPPO, private/account, device, secret, SMS, email, or external state changed.

## Root cause

The primary inferred a nested selection schema instead of inspecting the literal ticket property names first.

## Prevention

- Inspect each new JSON owner's top-level property names before projecting fields.
- Use only literal discovered property paths for selection/registration/authority review.
- Reject null projections when false was expected; do not reinterpret them as inactive.
- Register and replay the implementation memory gate before retry.

## Disposition

Registered truthfully before corrected ticket readback. The ticket agent's hashes and no-authority claim remain pending primary verification.
