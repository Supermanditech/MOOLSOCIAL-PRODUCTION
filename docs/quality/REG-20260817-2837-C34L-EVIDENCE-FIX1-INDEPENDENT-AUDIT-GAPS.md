# REG2837 — C34L evidence FIX1 independent audit gaps

Date: 17 August 2026
State: registered independent PRE-AAB-2 FIX1 rejection; zero external action

## Audit rejection

The independent source audit rejected PRE-AAB-2 FIX1 without running behavioral
gates because release-blocking trust boundaries remained:

1. Source attestation still accepts a caller-authored capture manifest and
   self-declared producer/session/digest values without binding the claimed
   digests to retained capture-artifact paths, hashes, and byte counts or an
   authoritative capture owner/signature. The combined fixture fabricates the
   same inputs, so REG2786's caller-fabrication root remains.
2. OPPO and journey evidence retain raw `deviceSerial` while the FIX1 ticket
   forbids raw device identifiers, then claim that no private value was recorded.
3. The retained gate does not bind lifecycle proof transition/phase/evidence
   path/hash/browser evidence or exact detailed/aggregate proof-record equality;
   the combined fixture passes with an unrelated prerequisite proof path/hash.
4. Windows path normalization checks two backslashes rather than one; privacy
   walkers scan values but do not reject forbidden property names; combined and
   retained fixtures lack deterministic cleanup; recovery tests a shadow model
   instead of confined real audit/apply; and OPPO crash coverage omits the two
   file-move-before-journal-update windows.

No build, transition, real recovery/apply, browser, Play, device, private, or
external action occurred.

## Required prevention

Bind each capture digest to an immutable retained capture artifact
path/SHA/bytes under an exact producer/type contract; replace raw device serials
with a nonreversible approved device-binding digest; compare the full newest
lifecycle proof record and both histories; correct single-backslash and forbidden
property-name validation; clean every unique fixture root safely; invoke actual
recovery audit/apply only inside exact fixture confinement; and cover both
post-move/pre-journal crash boundaries on both hosts before qualification.
