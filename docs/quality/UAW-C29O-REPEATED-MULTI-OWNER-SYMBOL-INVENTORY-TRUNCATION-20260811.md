# C29O repeated multi-owner symbol-inventory truncation

Date: 2026-08-11
Ticket context: `UAW-PERSONAL-MVP-SOCIAL-END-TO-END-ACTION-TRUTH-AND-ACCESSIBILITY-C29O`

## Rejected repeat

Immediately after registering the broad API-read truncation, a symbol-only
inventory still named three owners in one `rg` command. The result again
exceeded the output budget and was truncated. It is rejected in full and is not
evidence for ticket selection or product implementation.

No product, provider, device, protected release or scope state changed.

## Strengthened prevention

- One command may name only one exact API owner.
- Large-owner inventories must also include a bounded line interval or a small,
  exact symbol family.
- The command must report no truncation before its result is admitted.
- After any truncation, the next evidence call may not broaden the target set.
