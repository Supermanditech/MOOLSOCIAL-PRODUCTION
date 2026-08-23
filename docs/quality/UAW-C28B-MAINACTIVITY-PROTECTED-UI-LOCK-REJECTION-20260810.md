# C28B MainActivity protected UI lock rejection

- Date: 2026-08-10
- Phase: focused implementation qualification
- Passed first: regression memory, C28B source gate, C27B/C27D navigation
  gates and authorized MVP scope
- Material rejection: `check-approved-ui-locks.ps1` rejected the proposed
  `MainActivity.kt` window-fit adapter because that file is checksum-locked by
  accepted Screens 01–03.
- Device/build effect: none; r60.26 remained installed and no APK was built.
- Root cause: C28A necessity analysis selected a native Android owner without
  first intersecting it with every immutable Screens 01–03 production-file
  lock.
- Prevention: resolve protected file membership before selecting a runtime
  owner. Never mutate or re-seal `MainActivity.kt` for this successor. Use the
  existing unprotected shared Flutter system-UI owner and require the protected
  lock to pass unchanged.
