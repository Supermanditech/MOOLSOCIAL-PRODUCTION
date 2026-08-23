# C20G completion manifest hash refresh rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-HOST-QUALIFICATION-FIX3-C20G`

## Rejection

After both C20G host cycles passed, the completion seal truthfully changed the
C20G manifest state and added its qualification result. The first subsequent
delivery-discipline gate rejected because the selected-ticket assessment still
contained the pre-execution manifest SHA-256.

## Root cause

The lifecycle transition treated the manifest content and checkpoint digest as
independent fields. They are coupled: any truthful manifest mutation changes
the digest that the delivery lock must verify.

## Permanent prevention

Every later lifecycle mutation recomputes the literal current manifest hash and
refreshes the selected-ticket assessment before the delivery lock is retried.
`scripts/check-mvp-delivery-discipline-lock.ps1` remains the automatic stale-hash
rejection gate. No runtime, APK, install or device mutation occurred.
