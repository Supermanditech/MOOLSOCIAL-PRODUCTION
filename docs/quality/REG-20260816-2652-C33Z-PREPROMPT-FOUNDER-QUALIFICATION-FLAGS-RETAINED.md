# REG2652 — C33Z pre-prompt founder-qualification flags retained

Date: 2026-08-16 IST

C33Z passed its build-phase candidate gate with two qualified source cycles and
counts `0/0/0/0`. The founder-owned visible launcher then rejected before any
hidden prompt because the sealed state retained all three prior-candidate
founder configuration-qualification flags as `true` while the current candidate
had not received its hidden inputs.

No password, Firebase Android API key or Google OAuth server client ID was
entered. No wrapper or app-bundle build ran, no authority was consumed and the
counts remain `0/0/0/0`.

This is the same release-orchestration/state-reset defect family as earlier
candidate-control incidents, but the exact missed predicates are new. Reject
C33Z and require an exact successor. Before the successor seal, reset the three
qualification flags to `false`; require those values in source-qualified/build
gates and static parity with the launcher's same three boolean-only pre-prompt
predicates; set them `true` only after founder input validation inside the
launcher.
