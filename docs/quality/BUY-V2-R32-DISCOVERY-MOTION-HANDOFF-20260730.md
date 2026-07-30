# Buy V2 R32 media-first discovery and motion-foundation handoff

Recorded: 30 July 2026

State: `DEVICE_VERIFIED_FOUNDER_REVIEW_CANDIDATE`

Founder visual acceptance remains pending. R32 is an uncommitted native
Flutter candidate. It is not a release, deployment, production-signing event,
commit, push or authorization to modify the founder-FINAL HTML.

## Result

Ticket `BUY-FV2-093` is implemented and device verified. The compatible
foundations of Tickets `BUY-FV2-076`, `BUY-FV2-079` and `BUY-FV2-084` are also
device verified, but those broader motion, 3D, theme and advertising tickets
remain open.

- Default Shop, Wholesale and Medicine landings now lead with first-party
  promotions and one horizontally browsable, media-first product collection.
- The dense three-column catalogue remains below that collection.
- Search, category and Saved states continue directly to the compact grid.
- Featured product actions are stable 44-pixel targets and change in place
  from `+` to `− quantity +`.
- Product detail gives the truthful product gallery visual priority while
  preserving partner, delivery, product-fact, review, reporting and purchase
  owners below it.
- Product imagery keeps an honest category-specific first frame while the
  exact MoolSocial-owned image decodes; unrelated product photos are never
  substituted.
- Shared press, state-change and content-change timing tokens acknowledge
  interactions without fake waiting or perpetual motion. Reduced-motion mode
  resolves those transitions immediately.

No HTML, Screen 01–03, Social/YouTube, backend contract, database field,
vertical identifier or business rule changed.

## Repository and protected identities

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `5225bb8d36792cc8f7fb9dfcfe418b3f93b7ca1a`
- Final 28-file Buy source fingerprint:
  `B8D6AC0DD111F31652F171709C6FC827E98BF383FE7D4F142A78A2B850D01B73`
- Social protected tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`
- Screens 01–03 protected lock: passed
- Founder-FINAL Buy reference: 25 immutable files passed
- Approved HTML screenbook: unchanged and read-only

The six R32 implementation/test/ticket files recorded before the two Buy
regressions matched the post-regression state. No production source changed
after the exact device-review candidate was built.

## Exact candidate and OPPO identity

- Package: `com.moolsocial.app`
- Version: `1.0.0-r32` (`versionCode 2026073037`)
- Candidate id: `BUY-R32-DISCOVERY-MOTION`
- Device: OPPO CPH2375, serial `2b3e0f71`
- Candidate and pulled installed-base SHA-256:
  `A79E01076114B99EAB8CA76B6C3104DB6DA2BC28514018EA871B54F2A1268BB8`
- Candidate APK:
  `moolsocial-buy-r32-discovery-motion-device-review-debug.apk`
- Evidence:
  `artifacts/quality/buy-flutter-r32-discovery-motion-oppo-20260730-24`

The first R32 preflight APK is deliberately preserved as rejected build-mode
evidence. It omitted the physical-device review defines, correctly stopped at
Sign in, used `versionCode 2026073036`, and had SHA-256
`1972727E85BB7740F485403599054E6DAC8623AC129F4ACC234C85DE666C49FC`.
It is not the reviewed candidate.

## Verification completed

- Final full Flutter analysis: no issues
- Focused Buy screen suite: `56/56` passed
- Responsive capture generation/replay: `2/2` passed
- Responsive matrix: 73 Android/iOS-size and 140%-text images
- Complete Buy regression 1: `95` passed, `2` intentionally skipped
- Complete Buy regression 2: `95` passed, `2` intentionally skipped
- Route interaction contract: 154 unique routes passed
- Customer-copy Flutter gate: passed
- Customer-copy founder-HTML gate: 9 states passed at `390 × 844`
- Founder-FINAL Buy reference gate: passed
- Brand integrity: passed
- Approved Screens 01–03 and reference locks: passed
- Protected Social baseline: 119 files and exact tree passed
- Git diff hygiene: passed; only existing LF-to-CRLF notices were emitted
- Installed APK checksum: exact match, reconfirmed after the replay
- Startup diagnostic: correct candidate id and authenticated `stage=ready`
- Complete replay audit: no app fatal exception, package ANR, `E/flutter` or
  unhandled Flutter exception found

The first founder-HTML customer-copy attempt is preserved. It failed only
because the local read-only screenbook server was not running. The server was
then started against the approved screenbook, the unchanged gate passed all
nine states, and the server was stopped.

The device graphics sample contains only two Android-managed frames: zero
modern janky frames, 16 ms p50/p90/p95/p99 and 4 ms GPU percentiles. That
sample is too small for broad performance acceptance and is retained only as
a limited observation.

The repository-wide Flutter golden issue inherited from R30 remains outside
this R32 source change: 75 unrelated stale goldens contain the same
0.11-percent/425-pixel global Mool-rail difference. R32 did not overwrite or
accept those unrelated goldens, and this handoff does not claim a complete
repository golden pass.

## OPPO replay completed

The checksum-matched candidate replay covers:

- authenticated launch and Mool-to-Buy entry;
- Shop first view, horizontal featured-product browsing, add/quantity and the
  aggregate Cart owner;
- dominant product detail plus the below-fold partner, delivery, product fact,
  review and reporting content;
- Wholesale and Medicine media-first first views;
- the Medicine category overlay;
- Orders and live tracking progress;
- background/resume restoration of the exact Shop state; and
- the complete package-scoped fatal/ANR audit.

## Open founder-directed motion scope

R32 intentionally does not claim completion of:

- a motion identity/logo treatment;
- screen-specific themes;
- heavier or decorative 3D motion;
- live changing product data;
- sponsored advertising or video advertising; or
- broad low-end-device performance acceptance.

Those changes require the remaining ticket contracts, representative
performance evidence and founder review. R32 introduces no invented live data,
advertising contract or fake asynchronous behaviour.

## Acceptance boundary

This record proves implementation, same-source Buy regression,
protected-reference integrity, exact checksum installation and physical-device
replay. Founder visual acceptance and production release acceptance remain
pending. No commit, push, deploy, publication, HTML edit, Social edit or
production signing was performed.
