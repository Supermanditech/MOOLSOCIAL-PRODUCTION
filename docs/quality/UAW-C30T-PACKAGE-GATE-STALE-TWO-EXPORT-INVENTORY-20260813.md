# C30T package-gate stale two-export inventory

- Date: 2026-08-13
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
- Regression: `REG-20260813-1886-C30T-PACKAGE-GATE-STALE-TWO-EXPORT-INVENTORY`

## Observation

The first provider deployment wrapper invocation stopped in the delegated local package gate. TypeScript compilation and preceding containment checks passed, but the package gate rejected the compiled export inventory because it found `youtubeProvider`, `youtubeOAuthCallback`, `moolSocialContent` and `moolSocialChat` instead of its historic YouTube-only pair.

## Containment proof

- Firebase dry-run and deployment had not started.
- The ignored runtime was restored byte-for-byte to SHA-256 `5AED3DD3D27EE82EDDC4B76FD2AAD2082EEDB3C7E8DEB3109F1FC798242E4702`.
- `youtubeprovider-00036-qer`, `youtubeoauthcallback-00035-cir`, `moolsocialcontent-00004-gig` and `moolsocialchat-00001-yaf` remained latest-created, latest-ready and 100% traffic revisions.
- Hosting was not attempted.

## Required correction

The package gate must validate the exact current four-export compiled inventory while the deployment owner continues to pass only `functions:provider:youtubeProvider`. C30T Validate must exercise the same delegated package path without writing runtime or cloud state.
