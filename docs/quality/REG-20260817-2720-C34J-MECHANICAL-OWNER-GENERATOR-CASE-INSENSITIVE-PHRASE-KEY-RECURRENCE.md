# REG2720 — C34J generator case-insensitive phrase-key recurrence

Date: 2026-08-17 IST

The C34J mechanical owner generator repeated REG2712 by declaring uppercase
and lowercase variants of `authentication-privacy-safe` in one case-insensitive
PowerShell hashtable. Parsing stopped before the cycle runner or launcher was
created; no test, build or external action started.

The corrected generator retains only the uppercase phrase in the ordered map
and performs the lowercase phrase through an explicit case-sensitive
`String.Replace` afterward. This rule now applies to every case-distinct pair,
not only candidate identifiers. Both targets must be absent before the one
retained execution and all stale tokens are audited afterward.
