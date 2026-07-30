# Buy V2 R35.1 backend-contract boundary handoff

Date: 31 July 2026

State: `COMPLETE_NONVISUAL_PRODUCTION_HARDENING`

Ticket `BUY-FV2-109` machine-enforces the established fact that MoolSocial has
no approved Buy backend contract. It prevents an accidental direct transport,
mock production path or unreviewed backend owner from being treated as
production readiness.

## Authority

The founder directed that backend behavior, business rules, database fields
and API contracts must not be invented. The existing read-only audit records:

- 72 current backend files are YouTube-specific;
- the one repository contract is the account-setup journey;
- no approved Buy endpoint, transport schema, API error envelope, database
  model, identity boundary, authorization contract or retry/idempotency
  semantics exist.

This gate protects that absence. It is not a substitute for a future approved
contract.

## Gate

- Script: `scripts/check-buy-backend-contract-boundary.ps1`
- Gate SHA-256:
  `F223C823F12604B46F4EB29261D401F5522CA5EE4E166EFB1CDAAD48331251DB`
- Main quality command: `scripts/check.ps1`
- Release rule: item 28 under `Every pull request` in
  `docs/quality/RELEASE-GATES.md`

The gate scans:

- all `buy_v2_*.dart` feature files;
- every native Dart file under `apps/mobile/lib/ui_v2/buy`;
- every file under `backend/functions/src`;
- every file under `contracts`.

It rejects:

- direct HTTP, Dio, GraphQL, Firebase database/functions or `dart:io`
  transport imports and clients;
- WebView and URL-launcher imports for Buy production behavior;
- direct Buy/cart/checkout/inventory/catalogue/wholesale/medicine/order
  endpoint paths;
- external URL literals other than the established first-party
  `https://moolsocial.com/address/request` support action;
- mock, fake or review commerce gateways in the native V2 surface;
- fabricated `Future.delayed` business completion;
- backend paths, exported symbols and service/controller/repository/gateway
  owners that create an unapproved Buy backend;
- Buy contract files before the approval boundary is recorded.

The clean gate reports exact scanned inventory. Missing required roots fail
closed.

## Adversarial self-test

The built-in `-SelfTest` mode proves:

- direct HTTP import is rejected;
- WebView import is rejected;
- fabricated delayed completion is rejected;
- review gateway use is rejected;
- direct checkout endpoint is rejected;
- external Buy URL is rejected;
- an invented Buy checkout backend owner is rejected;
- the established first-party address-request URL is accepted.

The real native camera scanner, notice-lifetime timers and Flutter image
placeholder builder remain allowed because they are not backend behavior.

## Verification

- Boundary self-test: passed.
- Clean boundary gate: passed for eight mobile files, 72 backend files and one
  contract file.
- Full Flutter analysis: passed.
- Complete Buy regression 1: `111/111` passed; four opt-in capture generators
  skipped.
- Complete Buy regression 2: `111/111` passed; four opt-in capture generators
  skipped.
- Protected Buy baseline: passed.
- Protected Social baseline: passed.
- Approved Screens 01–03 and reference locks: passed.
- Founder-FINAL Buy reference: passed.
- Brand integrity: passed.
- User-facing Flutter copy: passed.
- HTML customer copy: `9/9` states passed.
- Interaction contract: `154` routes passed.
- Temporary HTML server exited and port 8765 was verified free.

## Protected and device identity

- Starting HEAD:
  `d2368eb26d3dff33c13d7c6033e35029670ae5cf`
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

No Flutter or backend runtime changed, so no APK rebuild or reinstall was
required.

## Evidence

`artifacts/quality/buy-r35-1-backend-contract-boundary-20260731-30`

Evidence contains the clean and adversarial gate logs, exact source
fingerprints, full analysis, two regressions, every protected/reference/copy
gate, HTML server lifecycle and read-only OPPO identity.

## Replacement rule

When a real Buy contract is approved, this absence boundary must be replaced
additively—not bypassed—with contract schema validation, adapter tests,
authentication/authorization tests, idempotency and unknown-outcome tests,
vertical isolation tests and backend audit-history checks. That future work
requires recorded authority and cannot infer missing rules.
