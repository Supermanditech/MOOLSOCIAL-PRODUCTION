# Buy V2 R35.1 data-egress boundary handoff

Date: 31 July 2026

State:
`COMPLETE_NONVISUAL_PRODUCTION_HARDENING_WITH_RECORDED_IDENTITY_FIXTURE_RISK`

Ticket `BUY-FV2-110` machine-protects the founder-approved native Buy V2
surface from accidental customer-data and credential egress before data
classification, consent, observability, redaction and retention contracts
exist.

## Gate

- Script: `scripts/check-buy-data-egress-boundary.ps1`
- Gate SHA-256:
  `BE184CC9E49FA87587628501D2AF2EA86375A73A95A59B3D1093DED76C016F0D`
- Main quality command: `scripts/check.ps1`
- Release policy: item 29 under `Every pull request`
- Clean inventory: eight native Buy V2 Dart files

The gate rejects:

- direct `print`, `debugPrint` or developer-log calls;
- direct analytics, crash-report event/detail and logger sinks;
- arbitrary clipboard reads and writes;
- direct system-share calls;
- unapproved SharedPreferences, Hive, SQLite or secure-storage ownership;
- imports that introduce those sinks;
- embedded private-key, API-key, secret-key or bearer-token patterns.

The sole clipboard allowlist entry is the established first-party
`https://moolsocial.com/address/request` support action. This narrow allowlist
does not authorize copying address, order, prescription, payment, search or
customer-contact data.

## Adversarial self-test

The built-in `-SelfTest` mode rejected:

1. customer-contact diagnostic logging;
2. direct analytics;
3. unapproved client storage;
4. system sharing;
5. arbitrary clipboard writing;
6. clipboard reading;
7. embedded bearer-token material.

It accepted the exact first-party address-request clipboard action and
ordinary presentation code.

## Residual identity fixture risk

The protected `BuyV2Session` contains two hard-coded review
recipient/contact/address fixture records. This is not a finding of active
logging or transport egress, but it is not a production identity source and
must not be treated as one.

The fixture values are intentionally omitted from new evidence. Safe removal
requires:

- an approved authenticated profile/address ownership contract;
- defined loading, absent-data, failure and retry semantics;
- migration/review of current account, checkout and order presentation;
- founder authorization for the visible/runtime change;
- a new additive protected Buy baseline and checksum-matched device replay.

This ticket neither allowlists the fixture as production data nor changes the
founder-approved runtime without that authority. Production acceptance is not
claimed.

## Verification

- Data-egress self-test: passed.
- Clean data-egress gate: passed.
- Backend-contract boundary: passed for eight mobile, 72 backend and one
  contract file.
- Full Flutter analysis: passed.
- Complete Buy regression 1: `111/111` passed; four opt-in capture generators
  skipped.
- Complete Buy regression 2: `111/111` passed; four opt-in capture generators
  skipped.
- Protected Buy baseline: passed.
- Protected Social baseline: passed.
- Approved Screens 01–03/reference locks: passed.
- Founder-FINAL Buy reference: passed.
- Brand integrity: passed.
- User-facing Flutter copy: passed.
- HTML customer copy: `9/9` states passed.
- Interaction contract: `154` routes passed.
- Temporary HTML server exited and port 8765 was verified free.

## Protected and device identity

- Starting HEAD:
  `26f3667971026384263a4809d540eab5027f7025`
- Protected Buy runtime files: `28`
- Protected Buy tree:
  `f712b5b8ce10dd92b64babc4703379a24918fef5cef9417afe9c6679db79bc5d`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`
- OPPO: `2b3e0f71`
- Installed version: `1.0.0-r35.1`
- Installed version code: `2026073045`
- On-device base APK SHA-256:
  `10FC8C43626B7C2882A6340C6A3A4710C2092E4D45AB0A768CE7056F23BCB9C7`

No application runtime changed, so no APK rebuild or reinstall was required.

## Evidence

`artifacts/quality/buy-r35-1-data-egress-boundary-20260731-31`

Evidence includes clean and adversarial gate logs, source fingerprints, full
analysis, two regressions, all protected/security/reference/copy gates, HTML
server lifecycle, a redacted residual-risk record and read-only OPPO identity.

## Future replacement

When data and observability contracts are approved, replace this absence
boundary additively with typed redacted events, consent enforcement,
classification tests, retention tests, sensitive-field denial tests and
verified server-side audit ownership. Do not weaken the gate with broad
allowlists.
