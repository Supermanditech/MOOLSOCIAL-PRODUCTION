# Social HTML, Flutter and Trial baseline

Date: 26 July 2026  
Branch: `remediation/prototype-conformance-2026-07-20`  
Status: **protected baseline before Buy**

## Outcome

Social is now governed as three traceable layers. A later Buy change must not
silently replace one layer with evidence from another.

### 1. HTML authority

`approved-references/manifest.json` owns the accepted HTML packages and their
individual checksums. `scripts/check-approved-ui-locks.ps1` verifies every
reference and every production-accepted Screens 01–03 source lock.

The latest accepted Social HTML authority remains Screen 04 `v8`:

- source SHA-256:
  `0997F3AD7ADAAD76EB3FD7F5A96CF63C1D691413DA92F368FC4EC005E0D86410`;
- status: `founder-delegated-final-html-gate-0`; and
- native Flutter acceptance: still false in the acceptance record.

The editable screenbook is currently on
`founder-review/youtube-screen04-2026-07-25` at
`2febd426c7ea254292c1e822221efc00b08a82f3`. Its working Screen 04 hash is
`667190F9E1837721BC6D9E4A19090FA089A67CFDF02A73FCE42DFE8408F91E93`.
That file is a later YouTube review draft, not accepted HTML authority.

The existing Screen 09 Buy draft hash is
`91EA647B56A5C017EA16346018394E63E39E06045E841A80E66EDA9410A4CF8B`.
It predates the unified catalogue/offer/workspace decision and must not be
promoted as the new Buy candidate.

The manifest raw SHA-256 when this baseline was recorded was:

`c099c3775d052d83078d5c72bfa9568016f68856a82575bebca3a29a9986e6c2`

That outer manifest hash is traceability metadata. The permanent authority is
the per-file checksum and acceptance data already enforced by the approved UI
lock.

### 2. Flutter and device authority

The latest exact retained Flutter binary verified on the founder-authorized
OPPO is:

- candidate: `youtube-return-oppo-20260726-10`;
- file:
  `artifacts/quality/youtube-private-dev-oppo-public-viewing-20260725-01/moolsocial-youtube-videos-shorts-private-dev-r10.apk`; and
- SHA-256:
  `4B69C0F284B9AA1AACF80C764F2B3497996CEA2E1728F068B896F0D6DF8798E9`.

The APK pulled read-only from OPPO `CPH2375` / serial `2b3e0f71` on 26 July
has that exact SHA-256. Android reports the app was last updated at
`2026-07-26 13:59:11`. The on-device screen visibly loaded the live public
YouTube Videos catalogue.

Evidence:

- `oppo-r10-live-videos-20260726.png`, SHA-256
  `9FA47C4F6E3E33B43C8B5218E981AAB17CD1E93649FFFD0CEC32BAE484950FEB`;
- `oppo-r10-live-videos-20260726.xml`, SHA-256
  `2F5E7ACFB593F0AA86538C6C4860C00080CA9369096A1D257EE166BF9DCCB693`;
  and
- `artifacts/quality/youtube-api-submission-readiness-20260725-01/OWNER-CONNECT-PROOF-AND-APP-RETURN-20260726.md`.

The current protected source also contains dormant owner/audit contracts added
after that public-viewing candidate. They remain disabled and are not claimed
as byte-identical to the retained APK.

After isolating the YouTube return adapter from the founder-accepted
`MainActivity`, the current source built successfully as a debug APK:

`97853D03A05DD6A74334AA0AEC4EC15BEF3F374FED049E6CE2F1024D7CF15C26`

That debug build proves compilation only. It has not been deployed or promoted.

### 3. Trial deployment authority

The retained private-Dev public viewing boundary is:

- Firebase/GCP project: `moolsocial-dev-503018`;
- capability profile: `PublicDataReview`;
- last recorded Cloud Run revision:
  `youtubeprovider-00024-dol`;
- current Firebase Functions deployment source hash:
  `8a3afd8e81e30322f1d64f13e3d79f6360516aab`;
- current Firebase state: both `youtubeProvider` and `youtubeOAuthCallback`
  `ACTIVE`;
- public data: enabled; and
- owner connect, owner actions, creator assets, Live, private upload and owner
  analytics: disabled.

Evidence:
`artifacts/quality/youtube-private-dev-oppo-public-viewing-20260725-01/LIVE-PUBLIC-VIDEOS-SHORTS-PROOF.md`.

The Trial deployment is not Production approval and is not a general
authorization to reactivate held YouTube capabilities.

## Protected source tree

`scripts/check-social-protected-baseline.ps1` hashes 119 Social, YouTube,
provider-adapter and dedicated regression files. Text line endings are
normalized for cross-platform Git checkouts; binaries use raw bytes.

Protected tree SHA-256:

`927BA8662457D64640EF3A3A97B2B53120CA53E26E80F761A937EE35BAD92851`

The immutable v8 captures remain preserved as historical accepted-reference
evidence. The later founder-authorized YouTube review lane adds a direct
YouTube Shorts filter, so the current shell has a separate operational golden
gate:
`apps/mobile/test/screen04_social_operational_baseline_test.dart`.
This separation prevents the later trial extension from rewriting the v8 HTML
record.

The provider dependency gate also passes at the required high-severity
threshold. A scoped `google-gax` → `rimraf@6.1.3` override removed the
high-severity `rimraf/glob/minimatch/brace-expansion` chain; the complete
Functions suite then passed `271/271`. Seven moderate transitive advisories
remain in the latest Firebase Admin Storage dependency family and are recorded
without applying npm's unsafe breaking downgrade recommendation.

## Baseline verification result

- Dart format: pass.
- Flutter analysis: no issues.
- Full Flutter regression: `572` passed, `4` historical fixtures skipped,
  `0` failed.
- Full regression log SHA-256:
  `F34AA4CF6FBF6424C4E0E7B4CF0E7D94AAFA36F1711E86F804A0190B675DF569`.
- Operational Social/YouTube return focused regression: `8` passed and the
  historical v8 capture fixture skipped.
- Android debug build: pass.
- Functions: `271/271` pass.
- High-severity production dependency audit: pass.
- Customer-copy gate: pass.
- Interaction-contract gate: pass across `153` routes.
- Approved UI locks: pass.
- Protected Social tree: pass across `119` files.

The tree lock intentionally excludes shared routing/session files that Buy may
need. Those boundaries remain protected by the approved UI lock, customer-copy
gate, interaction-contract gate, full Flutter tests, Android/iOS builds and
affected-journey replay.

## Git and CI gates before a Buy deployment trial

1. Approved HTML/reference and Screens 01–03 production locks.
2. Protected Social source-tree checksum.
3. Production-facing customer-copy gate.
4. Interaction and route-contract gate.
5. Full Flutter format, analysis and tests, including Social goldens.
6. Provider Functions typecheck, tests and production dependency audit.
7. Android debug build and iOS simulator build.
8. Exact accepted Buy HTML checksum and interaction evidence.
9. Native Flutter parity against that accepted Buy reference.
10. Social plus Buy clean-state regression on the physical OPPO.
11. Read-only verification that the retained Trial provider boundary has not
    broadened.

The Buy deployment trial is blocked until the complete Buy HTML-to-Flutter
slice passes all applicable gates. HTML approval alone cannot trigger a
deployment.

## Repository synchronization rule

The exact source baseline becomes remotely durable only through an intentional
commit and push on the remediation branch after the gates pass. Large retained
APK evidence is identified by path and SHA-256 and must not be mistaken for a
normal Git source file or silently replaced by a newly built binary.
