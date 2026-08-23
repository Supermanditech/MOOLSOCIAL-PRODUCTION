# UAW C33F FIX3 founder-authorization timestamp correction

Date: 2026-08-15

The exact founder action was recorded correctly, but the initial
`receivedAtUtc` timestamp was rounded without reading an authoritative clock.
The correction is to replace it with an exact `recordedAtUtc` value obtained at
repository persistence time. The authorization scope itself is unchanged.
