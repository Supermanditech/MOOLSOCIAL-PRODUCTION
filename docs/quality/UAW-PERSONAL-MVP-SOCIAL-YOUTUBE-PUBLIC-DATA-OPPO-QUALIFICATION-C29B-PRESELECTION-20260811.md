# C29B Social YouTube public-data OPPO qualification preselection

- Ticket: `UAW-PERSONAL-MVP-SOCIAL-YOUTUBE-PUBLIC-DATA-OPPO-QUALIFICATION-C29B`
- Candidate: `1.0.0-r60.29` (`2026081129`), profile, one build maximum
- Device: founder-authorized OPPO CPH2375 serial `2b3e0f71`
- Predecessor: installed and preserved `1.0.0-r60.28` (`2026081028`), SHA-256 `FD0C1BDE24A1892C7A4E8B82504B19A88057CB63FACAE22E3BE014573843AEE6`

## Reuse and smallest complete scope

C29B consumes the passed C29A source seal and reuses the existing one-build wrapper, APK gate, Firebase Android app, persistent `PublicDataReview` provider, profile official player and accepted navigation. It creates no screen, route, backend, state, provider or build pipeline.

The wrapper may perform one profile build using the exact Dev Android SDK configuration retrieved in memory from Firebase Management API. No configuration value is logged or stored in provenance, and no YouTube server secret enters the APK. After build, the artifact must be checksum-unique from r60.28, signed by the same registered certificate, versioned exactly r60.29, and rechecked before an in-place `adb install -r` to the exact serial. Uninstall, data clear and downgrade remain forbidden.

Device qualification covers launch/startup identity, genuine Play Integrity App Check, live `capabilities.publicData`, real Shorts catalogue, official embedded playback, swipe-next, external YouTube escape, MoolSocial Save/Discuss/Share, truthful unavailable/error/retry, Back/navigation, lifecycle/app-switch/force-stop recovery and installed checksum identity. All evidence is preserved before founder review.

## Exclusions

No cloud write/redeploy, server secret value, OAuth/owner/upload/live/analytics capability, Production/Staging/HTML, commit/push, provider/customer message/call, fund movement, uninstall, data clear or downgrade is authorized.
