# C29R YouTube quota purpose and shared catalogue refresh — host qualification

Date: 2026-08-11
Branch: `remediation/prototype-conformance-2026-07-20`
HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`
Ticket: `UAW-PERSONAL-MVP-SOCIAL-YOUTUBE-QUOTA-PURPOSE-AND-CATALOGUE-REFRESH-C29R`
State: `source_qualified_external_dev_measurement_and_oppo_pending`

## Customer outcome

Automatic YouTube Shorts opening no longer invokes the uncached explicit-user
search path. All app instances share one durable eligible India-news Shorts
catalogue with a 30-minute TTL, a two-minute cross-instance refresh lease, a
four-page/20-item ceiling and a six-hour bounded stale fallback. Explicit user
search remains separately metered.

This complements C29T's already source-qualified process snapshot/background
refresh behavior: reopening Videos or Shorts retains qualified content instead
of showing a repeated loading popup. Neither C29T nor C29R has been installed on
OPPO in this source-only phase.

## Implemented production boundaries

- Added `publicShortsCatalogue` at the authenticated App Check-protected Dev
  provider boundary; the automatic Flutter Shorts loader invokes only this
  operation.
- Added a server-only Firestore snapshot, atomic refresh lease, stale recovery
  and durable catalogue outcome counters.
- Eligibility requires public, processed, embeddable, provider-available for
  India, not region-blocked, creator-declared Shorts between 1 and 180 seconds.
- Kept `publicSearch` and `search.list.explicit` solely as the explicit user
  search contract.
- Added atomic per-operation local quota decision measurements for search,
  upload and general buckets. The stored field is deliberately named
  `acceptedLocalReservations`; it is not represented as YouTube provider quota
  units.
- Added machine-readable purpose, privacy, non-claim and external-gate evidence
  at
  `config/uaw-personal-mvp-social-youtube-quota-purpose-c29r-evidence.json`.
- No watch history, Watch Later state, user preference, recommender input or
  engagement incentive enters the snapshot or measurement documents.

## Focused and full qualification

Two fresh sealed cycles produced identical results:

- Dart no-change format check: 3 files, 0 changes.
- Full Flutter analysis: clean.
- Protected Social/YouTube Flutter journey set: 24 files, 155 passed and five
  intentional immutable reference-capture skips per cycle.
- Backend strict typecheck: clean.
- Complete backend suite: 495 of 495 passed per cycle, including eight new
  shared-catalogue, lease, stale, eligibility, metering and corruption tests.
- C29R source gate: passed per cycle.
- MVP scope and robust 60–75-day delivery gates: passed per cycle.
- Permanent regression-memory gate: passed per cycle.
- Dependency audit at high severity: zero high or critical findings. Seven
  moderate findings remain in the current Firebase Admin Storage dependency
  lineage; the available audit-force path is a breaking downgrade and was not
  applied.

The final 14-owner source aggregate SHA-256 is
`E42D412EF02B1D26A6D493C0A7CE302D240FBDD30CDA73C0E129D97A80CAE164`.
The ticket manifest is sealed separately in the active MVP scope state at
`5D2F6BB9E045806CC17D0293FEB82927E98962FECFA11CF69084D9592B79BC6A`.

## Preserved gates and remaining work

The independent approved-UI lock remains rejected by a pre-existing Social
expansion in the shared customer-copy test. C29R preserved its observed
checksum `8BB8D600D9072C69543D38B8FC20868DA7F352CFB554D5891E624BF997351CF9`
and did not alter immutable Screens 01–03 or the approved screenbook. Reference
reconciliation remains separately gated.

`adb devices -l` reported no connected device at final host qualification.
Machine state still protects OPPO `2b3e0f71`, installed `1.0.0-r60.34`
(`2026081134`) and APK SHA-256
`96FD2F2E958D682481737A4DEA069086DE42E616409345E6218CF8831F999F29`.

After the founder reconnected the phone, a separately retained read-only audit
reconfirmed exact serial `2b3e0f71`, model `CPH2375`, versionName
`1.0.0-r60.34`, versionCode `2026081134` and the same installed APK checksum.
The launcher was foreground; the protected app was not launched or tapped.
Evidence:
`artifacts/quality/uaw-personal-mvp-social-c29r-protected-oppo-read-audit-20260811-01/identity.json`.

Before a successor APK or founder OPPO review, separate authority and gates are
still required for the Dev deployment, service-account/IAM qualification,
representative provider quota measurement window, endpoint build define,
fresh APK machine state, build, install and device replay. No provider form or
message was submitted; no API was enabled; no credential value was accessed;
and no deploy, build, install, uninstall, data clear, downgrade, commit, push or
Production write occurred.
