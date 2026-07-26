# VetoNews OwnerConnect proof and MoolSocial app return

Date: 26 July 2026 (Asia/Calcutta)  
Environment: dedicated private Dev only (`moolsocial-dev-503018`)  
Device: OPPO CPH2375, serial `2b3e0f71`  
Owner: VetoNews / `UC7rn0BIzhULpyw1NYXh-mWQ`  
Owner test user: `vetonewslive@gmail.com`

## Outcome

The bounded OwnerConnect proof body completed against the exact VetoNews
channel. Google account selection, VetoNews brand-account selection, the
unverified-test-app warning and `youtube.readonly` consent were completed on
the founder-authorized OPPO. The backend reconciled the connected identity to
`UC7rn0BIzhULpyw1NYXh-mWQ`.

The integration runner then reported only an end-of-test
`SemanticsHandle was active` cleanup failure caused by the supervised
UIAutomator evidence capture. The connection/reconciliation assertion had
already passed. This is therefore a passed proof body with a runner-cleanup
caveat, not a clean end-to-end test-runner exit.

The proof window automatically rolled back. Persistent `PublicDataReview` was
then restored and read-only verified. Final cloud state keeps every owner,
write, upload, Live and Analytics capability disabled.

## Firebase authentication prerequisite resolved

- Firebase Authentication initialized in the exact Dev project.
- Google is the only enabled sign-in provider.
- Anonymous and email/password sign-in remain disabled.
- Android signing SHA-1 registered:
  `1E4345AA0707C8A4C74F5485B47B14E911923B46`.
- A real Firebase Google session for the controlled VetoNews user was created
  and restored on the OPPO before the bounded owner proof.

No Firebase UID is shown in customer copy.

## OAuth browser return now deployed

The Dev `youtubeOAuthCallback` now returns a no-store HTML page that
immediately navigates to one of these token-free application routes:

```text
moolsocial:///app/creator/youtube-connect?youtubeConnect=complete
moolsocial:///app/creator/youtube-connect?youtubeConnect=failed
```

The page also retains a visible **Open MoolSocial** fallback. The app route
contains no OAuth code, state, token, email, channel ID or internal MoolSocial
user ID.

The result parameter is a presentation signal only. It does not write durable
connection state; backend connection status remains authoritative.

The callback deployment completed successfully for both `youtubeProvider` and
`youtubeOAuthCallback`. A live failure-branch request returned the expected
HTML redirect, Content Security Policy and `cache-control: no-store`. The
success and failure page generator has deterministic automated coverage.

## Final OPPO application proof

Installed candidate:

```text
youtube-return-oppo-20260726-10
```

APK:

```text
moolsocial-youtube-videos-shorts-private-dev-r10.apk
SHA256 4B69C0F284B9AA1AACF80C764F2B3497996CEA2E1728F068B896F0D6DF8798E9
```

Android resolves the custom scheme to
`com.moolsocial.app/.MainActivity`. Both the warm browser-return path and the
killed-process/cold-start path reach the same native Flutter screen:
`YouTube Connect`.

The screen shows this customer message:

> YouTube is connected to your MoolSocial account. You can now use eligible
> YouTube videos and Shorts in MoolSocial.

The screen-owned live-region banner disappears after five seconds. The app
remains on the same YouTube Connect screen.

Final-candidate cold-start evidence:

- `oppo-youtube-return-r10-cold-success-visible.png`
- `oppo-youtube-return-r10-cold-success-visible.xml`
- `oppo-youtube-return-r10-cold-success-dismissed.png`
- `oppo-youtube-return-r10-cold-success-dismissed.xml`
- `oppo-youtube-return-r10-logcat-filtered.txt`

Warm-return evidence was first captured on the immediately preceding
presentation-equivalent r9 candidate:

- `oppo-youtube-return-r9-warm.png`
- `oppo-youtube-return-r9-warm.xml`

## Verification

- Functions: `271/271` tests passed during the deployed restore.
- Flutter focused set: `23/23` tests passed.
- Flutter analysis for the return route/session/screen changes: no issues.
- Existing Android embedded-player source gate: passed.
- Android debug APK build including native cold-start routing: passed.
- OPPO cold return, exact screen, visible message and disappearance: passed.
- OPPO log scan: no fatal or unhandled exception in the final run.

## Final boundary

- Dev `PublicDataReview`: live and verified.
- Owner Connect: disabled after the supervised window.
- Owner Actions: disabled.
- Creator Assets: disabled.
- Live: disabled.
- Private Upload: disabled.
- Owner Analytics: disabled.
- Staging and Production: unchanged.

This evidence does not authorize comprehensive YouTube development, a
Production project, OAuth verification submission, YouTube audit submission or
quota submission. Those remain separately founder-gated.
