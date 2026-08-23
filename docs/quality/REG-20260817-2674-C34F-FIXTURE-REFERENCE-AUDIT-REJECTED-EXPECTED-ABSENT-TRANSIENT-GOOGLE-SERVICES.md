# C34F fixture reference audit rejected expected-absent transient google-services

Date: 2026-08-17 IST

Status: registered pre-seal; exact expected-absent transient allowlist required

A read-only fixture-reference audit incorrectly threw because
`apps/mobile/android/app/src/release/google-services.json` does not exist.
That transient founder-created file is required to remain absent before hidden
input validation and build; its absence is correct.

Rerun with only that exact path allowlisted as expected absent, require every
other durable referenced file to exist, prove the transient remains absent,
and do not inspect, create or copy it. No source cycle, hidden input, build,
browser, Play or OPPO action occurred.
