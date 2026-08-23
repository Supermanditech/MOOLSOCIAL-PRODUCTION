# C30Q Play install predecessor-signer incompatibility rejection

Date: 2026-08-12

## Disposition

The founder reported completing the Google Play install flow on the connected
OPPO CPH2375. Immediate read-only package-manager verification rejected the
claimed candidate install: `com.moolsocial.app` remained version
`1.0.0-r60.40` (`2026081240`) with installer `pc`. No C30Q candidate install is
counted.

## Cryptographic cause

The preserved installed APK was pulled read-only from the package-manager path
and matched the sealed predecessor SHA-256 exactly:

- installed/predecessor APK SHA-256:
  `50A5CBA08A68895B3BCCCB235E5BD7209CBDDC45673BA5FC607F365C611F5121`
- installed signer DN: `C=US, O=Android, CN=Android Debug`
- installed signer SHA-256:
  `CBDFC5969AD51ED570AFB1CF2FE60377E559D43F59D59E2AB66CCAF78EA9AC25`
- C30Q Google Play App Signing SHA-256:
  `47B28C7DDE2B61CAB6A7748C9019A3B57376B3BE1DC163D48253BBA35B63CDD9`

Android package updates require a compatible signing lineage. The existing
debug signer and the Play App Signing identity are distinct and have no
qualified lineage, so Google Play cannot replace this sideloaded predecessor in
place.

## Founder screenshot confirmation

The founder captured the OPPO Play Store result at 22:30. The listing recognized
the installed package, displayed `Uninstall` and `Update`, and then showed the
modal message `Can't install com.moolsocial.app (unreviewed)`. The underlying
listing remained on `Update`; no candidate installation completed. This visible
failure is consistent with the independently proven signer incompatibility and
does not justify another retry.

## Impact and preserved boundaries

- C30Q remains active only on Google Play Internal Testing.
- Upload count remains exactly one and candidate install count remains zero.
- r60.40 remains installed and its data directory, UID and first-install
  continuity remain preserved.
- No uninstall, data clear, downgrade, ADB successor install, second upload,
  Production/open/public rollout, email or quota action occurred.
- App Check and live reviewer journeys cannot truthfully be qualified until a
  Play-signed install exists.

## Permanent prevention

Before promising any in-place Play transition from a sideloaded predecessor,
compare the installed APK signing certificate with the Play App Signing
certificate or a qualified signing lineage. A different signer is a hard
preinstall rejection. Do not repeat the C30Q install flow. Any recovery that
removes the installed package or its data requires a new exact founder decision
and machine-authorized scope.

## Retained evidence

- `artifacts/quality/uaw-personal-mvp-social-play-internal-youtube-compliance-c30q-r60-43-20260812-01/07-predecessor-r60-40-installed-base.apk`
- `artifacts/quality/uaw-personal-mvp-social-play-internal-youtube-compliance-c30q-r60-43-20260812-01/08-play-install-signer-incompatibility.json`
- `artifacts/quality/uaw-personal-mvp-social-play-internal-youtube-compliance-c30q-r60-43-20260812-01/09-oppo-play-install-issue-founder-screenshot.jpg`
- `artifacts/quality/uaw-personal-mvp-social-play-internal-youtube-compliance-c30q-r60-43-20260812-01/10-oppo-play-install-issue-screenshot-analysis.json`
