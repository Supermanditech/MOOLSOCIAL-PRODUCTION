# C30Q Google Play Internal Testing active-release evidence

Observed: 2026-08-12T21:54:15.0670150+05:30
Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-YOUTUBE-COMPLIANCE-C30Q`

## Exact distribution boundary

- Provider account: `supermanditech@gmail.com`
- Organisation: `Supermandi Tech Private Limited`
- Play app ID: `4974778280277295872`
- Package: `com.moolsocial.app`
- Authorized and used track: Google Play Internal Testing only
- Internal track ID: `4700716609720808604`
- Track status: `Active`
- Production rollout: not performed
- Open/closed testing rollout: not performed
- Public listing rollout: not performed

## Accepted artifact

- Release: `2026081243 (1.0.0-r60.43)`
- Uploaded filename: `MoolSocial-1.0.0-r60.43-2026081243-release.aab`
- Sealed local AAB SHA-256: `E7E7DF249C71195FF9EDF8FD0247AEB64C91FEC3DD541F4A5A8FD11690AD8A69`
- Sealed bytes: `94475642`
- Qualified upload certificate SHA-256: `63491BE78A01F4514319AE5D2A3957611833F32CA1CBFD57AB2982B01D39C0D6`
- Play App Signing certificate SHA-256 registered in Firebase: `47B28C7DDE2B61CAB6A7748C9019A3B57376B3BE1DC163D48253BBA35B63CDD9`
- Google Play review page status before publication: `Ready to release`
- Google Play artifact row: API levels `24+`, target SDK `36`, four screen layouts, three ABIs and four required features
- Estimated new-install download: `27.7 MB`; estimated download time shown: `15 s`
- Google Play attached ReTrace mapping and native debug symbols to the app bundle row.

## Release result

- Release name: `2026081243 (1.0.0-r60.43)`
- Release notes language: `en-GB`
- After the final scoped `Save and publish` confirmation, Google Play returned to the Internal Testing track with status `Active`, latest release `2026081243 (1.0.0-r60.43)`, and no remaining draft.
- Google Play warned that changes usually appear within one hour and can occasionally take longer. The Play install is therefore a separately pending gate.

## Tester access

- Attached tester list: `MoolSocial Founder Internal`
- Attached tester count shown by Play: `1`
- Valid opt-in link: `https://play.google.com/apps/internaltest/4700716609720808604`
- Temporary Play app name shown before store review: `com.moolsocial.app (unreviewed)`

No Gmail draft, email send, YouTube quota submission, Production rollout, device uninstall, data clear, downgrade, ADB successor install, or OPPO install was performed by this release action.
