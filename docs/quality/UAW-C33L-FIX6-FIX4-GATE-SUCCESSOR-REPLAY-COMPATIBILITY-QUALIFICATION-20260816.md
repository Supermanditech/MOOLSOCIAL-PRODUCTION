# C33L FIX6 FIX4 gate successor replay compatibility qualification

Date: 2026-08-16 IST
Ticket: `UAW-C33L-FIX6-FIX4-GATE-SUCCESSOR-REPLAY-COMPATIBILITY`
Classification: `mvp_required`

## Outcome

The FIX4 aggregate-mirror prevention gate now supports two exact lifecycle modes:

- direct `active_FIX4` qualification when FIX4 is the current and selected ticket and its selected manifest hash is exact;
- `qualified_successor_replay` when the current and selected successor ticket are internally consistent and the prior FIX4 assessment pins the exact qualified FIX4 ticket hash, qualification state and retained evidence.

No wildcard successor is accepted. Wrong current/selected identity, wrong FIX4 hash, wrong qualification state or missing FIX4 evidence fails closed.

## Qualified source

- replay-capable FIX4 gate: SHA-256 `3AB3854440EFA77FD41CF8881D3A74D0914F6636809ED07F45221005872EFBB6`
- FIX6 behavioral gate: SHA-256 `779EFC4743C1FF301AFC744C49FC8CDA1D0A736932E58241A54D14D46F134640`
- pre-qualification FIX6 ticket SHA-256: `BC7DBDEC44164D2BC6ED721C5BD1BE5520AEF1B096D797F08CBB7FD1D296EF45`
- regression registry at qualification preparation: 2533 entries, SHA-256 `F4F457F9AB3BF02B52983EE569D1349CAE0C802572E9C251077A54C9B6045A87`

## Evidence

- both repaired gates parsed with zero errors;
- PowerShell 7: active `1/1`, successor `1/1`, negative `4/4`, live successor replay passed;
- Windows PowerShell 5.1: active `1/1`, successor `1/1`, negative `4/4`, live successor replay passed;
- the unchanged FIX4 aggregate successor/legacy/malformed-state matrix passed inside live replay;
- MVP delivery and FIX6 scope gates passed with build, Play, OPPO and external actions held;
- regression memory passed before implementation and retry.

FIX6 performs no build, upload, install, device, backend, provider, email, SMS, quota, funds or credential action. No production-readiness claim is made.
