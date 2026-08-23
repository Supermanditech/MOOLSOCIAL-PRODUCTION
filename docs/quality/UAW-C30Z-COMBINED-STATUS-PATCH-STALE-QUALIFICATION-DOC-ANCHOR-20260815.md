# C30Z combined status patch stale qualification-document anchor

Date: 2026-08-15
Regression: `REG-20260815-2224-C30Z-COMBINED-STATUS-PATCH-STALE-QUALIFICATION-DOC-ANCHOR`
Status: resolved; exact tails read and split bounded hunks applied

## Finding

A combined status patch used a closing sentence from the Screen 03 gate
incident document as context in the separate C30Z qualification document.
`apply_patch` rejected the complete patch before changing any target.

## Prevention

Each narrative target's exact tail is read independently. Registry, assessment
and documentation updates use small bounded hunks, and an atomic failure is
verified before retry. No source, build, Play, OPPO, provider, credential or
external-service state changed.
