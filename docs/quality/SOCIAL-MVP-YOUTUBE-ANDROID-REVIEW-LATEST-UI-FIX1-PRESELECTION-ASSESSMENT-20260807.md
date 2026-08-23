# Latest-UI YouTube Android review successor — preselection assessment

Date: 7 August 2026
Ticket: `SOCIAL-MVP-YOUTUBE-ANDROID-REVIEW-LATEST-UI-FIX1`
Classification: `mvp_required`
State: `REGISTERED_SCHEDULED_FOR_2026_08_08_NOT_ACTIVE`

## Customer outcome

The YouTube reviewer receives one Android install link for the latest qualified
MoolSocial MVP experience, with real Dev YouTube discovery, metadata and
official embedded playback. The candidate must feel like the current product,
not the obsolete r20 review shell or the emulator-bound r60.8 device profile.

## Robustness and reuse checkpoint

The implementation reuses the existing native Social Shorts, Videos, Feed and
Create owners; the current Universal/Mool navigation; the existing public
YouTube discovery/metadata adapter and official player host; the existing
read-only channel-connection boundary; `moolsocial-dev-503018`; and Firebase
App Distribution Preview inside Dev. The old r20 APK is retained only as audit
evidence. r60.8 is retained as OPPO navigation evidence and is prohibited from
provider submission because its review runtime is emulator-bound.

Duplicate search disposition: `reuse`, `configuration`,
`thin_policy_adapter`, and `test_only_acceptance`. No new screen, named route,
backend owner, provider project or distribution environment is necessary. Any
discovery-to-latest-UI compatibility gap must be implemented as the smallest
adapter in an existing owner and separately justified before code is written.

## Qualification retained for activation day

- Recheck current official YouTube policy, required-minimum-functionality and
  quota/audit authorities before enabling a real-provider build.
- Bind the build to Dev without `MOOLSOCIAL_DEVICE_REVIEW` or emulator runtime.
- Cover public Shorts, Videos, distinct selections, channel metadata, official
  player return, removed/private/non-embeddable, quota/offline and OAuth return.
- Run two affected host regressions, exact machine build gates, an in-place OPPO
  journey and checksum verification.
- Create the Dev App Distribution link only after qualification, then verify a
  tester-access install path before preparing the provider reply.

Timeline impact is two to four days and remains inside the 60–75-day MVP lock.
No implementation, build, device install, Firebase distribution or provider
write is authorized on 7 August by this scheduled registration.
