# C28B completion — Android navigation viewport implementation

State: complete.

## Outcome

- Added one shared Flutter startup viewport policy that requests visible status
  and navigation overlays on Android where the OS permits it.
- Preserved the approved C27 58px rail, every label/icon/colour/selected token,
  six-family catalogue, 18 local actions, Mool switcher, routes and state.
- Restored `MainActivity.kt` to its exact accepted Screens 01–03 SHA-256
  `5DCEB1482F366C2A4DC1ECF0A2A85C5AEF73AE341D18D1E977E46BEE76F8298C`
  after the protected lock rejected it; no lock was weakened or re-sealed.

## Verification

- Focused Dart format: clean.
- Focused analyzer: clean.
- Focused Flutter tests: 9 passed.
- C28B, C27B and C27D source gates: passed.
- MVP scope/delivery, permanent regression memory and approved UI locks:
  passed.
- APK build/install: not authorized and not performed; r60.26 preserved.
