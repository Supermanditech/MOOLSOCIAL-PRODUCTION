# REG2638 — C33U post-upload historical Play evidence raw privacy-boundary breach

Date: 2026-08-16 IST

Google Play Internal Testing activation for r60.59 completed successfully at
one build and one upload, with no OPPO install or device acceptance. During
post-upload repository recording, a broad raw read of an older retained Play
evidence JSON exposed fields containing a private account identifier and a
private tester link. No secret value, OAuth value, token, private key, email
action code or attestation payload was accessed, and the exposed private
values are intentionally omitted from this incident record.

The lookup should have selected and projected only an allowlisted set of
non-private schema keys. Future historical Play-evidence comparisons must use
property-name inventory or an allowlisted projection that excludes account,
tester identity and link fields before any content reaches agent output. Raw
reads of historical Play evidence are prohibited.

Because the incident occurred after the C33U source seal and after Internal
Testing activation, C33U is retained truthfully at `1/1/0/0`, rejected before
any OPPO action, and requires an exact successor under the no-regression rule.
