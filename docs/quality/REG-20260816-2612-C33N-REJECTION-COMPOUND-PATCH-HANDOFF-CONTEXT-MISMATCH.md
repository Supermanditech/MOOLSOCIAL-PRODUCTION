# REG-20260816-2612 — C33N rejection compound patch had a handoff context mismatch

Date: 2026-08-16 IST

The first attempt to persist the r60.52 rejection combined the rejection
document, detailed state, aggregate state and handoff append in one patch. Its
handoff hunk used text whose line wrapping did not exactly match the live file,
so `apply_patch` rejected the complete patch before applying any part of it.
The failed patch is not counted as a state transition.

The correction is to register this mistake, read the exact live tails and
state anchors, then apply the rejection document, detailed state, aggregate
state and handoff as separate bounded patches with readback after each. No Play,
OPPO, AAB retry, source, secret, provider or deployment action occurred.
