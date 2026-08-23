# REG3101 — YouTube OAuth return test retained triple-slash URL parsing

- Date: 2026-08-21
- Status: registered before retry

Backend verify completed 578/579 after the canonical YouTube custom-return URL
changed to `moolsocial://app/creator/youtube-connect`. The success return-page
test still parsed the old triple-slash shape and expected a now-missing segment,
so one assertion returned undefined. No build, deployment or device action
followed.

Prevention: parse the generated return URL with `URL`, assert scheme, authority,
path and exact single result parameter independently, and never index raw URL
segments.
