# C30P exact Play Internal Testing build-tooling successor findings — 2026-08-12

## Founder disclosure and classification

- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-YOUTUBE-COMPLIANCE-C30P`.
- Classification: `mvp_required`.
- Customer outcome is unchanged from C30O: one production-grade Dev AAB must
  be distributed only through Google Play Internal Testing, installed through
  Google Play on the OPPO, and prove the bounded MoolSocial and YouTube
  reviewer journeys before an unsent response is presented to the founder.
- C30P changes no application feature, screen, route, backend, provider,
  corpus or declared YouTube use case. It owns only the exact release-tooling
  successor required after C30O consumed its build authority without an AAB.

## C30O disposition

C30O is closed as `single_release_AAB_failed_authority_consumed`. Its launcher
ran under Windows PowerShell 5.1 and a benign Flutter Kotlin plugin warning on
stderr became a terminating `NativeCommandError`. Exactly one C30O wrapper
invocation and attempted build are recorded. No AAB, upload, Play install or
Create write occurred. The Firebase transient define file was erased and no
secret value was accessed by Codex.

## Smallest complete correction

1. Require PowerShell 7 before founder prompts or machine-state mutation in
   both the founder launcher and build wrapper.
2. Disable native-command error promotion only around the captured Flutter
   process, preserve both stdout and stderr in the durable log, restore the
   caller preferences immediately afterward, and use the true native exit
   code as the build outcome.
3. Use a new exact candidate `1.0.0-r60.42` (`2026081242`) and one fresh build
   authority. Never rerun or reuse C30O.
4. Re-run two identical complete source cycles because the build/gate owners
   change, then require the unchanged MVP, delivery, signing, App Check and
   distribution gates.

## Preserved boundaries

- Branch `remediation/prototype-conformance-2026-07-20`, HEAD
  `f6dfe7587aa02d782e94282d14af8bafff48ded0`.
- OPPO `2b3e0f71` keeps r60.40 until the separately qualified Play install.
- Firebase/Gmail account remains `hello@moolsocial.com`; Google Play remains
  `supermanditech@gmail.com`.
- Play app `4974778280277295872`, founder tester list, Dev project link,
  Firebase Play Integrity provider, public upload certificate and Play app
  signing certificate registrations remain preserved.
- Internal Testing only. Production, open/public testing, non-Dev backend,
  email/quota submission, secret access, uninstall/data clear/downgrade,
  commit/push and a second build/install remain forbidden.
