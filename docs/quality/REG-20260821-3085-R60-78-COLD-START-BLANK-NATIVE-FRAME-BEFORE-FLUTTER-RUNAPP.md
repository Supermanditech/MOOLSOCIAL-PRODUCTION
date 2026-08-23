# REG3085 — r60.78 cold start remained blank before Flutter runApp

- Date: 2026-08-21
- Status: registered before successor implementation
- Rejected version: `1.0.0-r60.78+2026082178`

## Incident

The checksum-qualified r60.78 update installed without data loss and no longer
showed the update-required fallback. Cold start nevertheless remained on the
plain navy native launch frame. The app process stayed alive, with no fatal or
AndroidRuntime marker. Production `main()` awaited Firebase, optional App
Check activation, preferences and auth-return preparation before the first
normal `runApp`, leaving no Flutter-owned first frame or bounded recovery.

## Escaped prevention gap

Earlier cold-start rules existed for later Play qualification, but the APK
prebuild contract did not require an installed checksum-matched candidate to
render a named Flutter-owned first frame before auth testing. Unit source gates
therefore passed while the real device remained blank.

## Required prevention

- render a named Flutter bootstrap frame before any asynchronous platform
  initialization;
- bound every pre-app asynchronous bootstrap stage;
- replace the bootstrap frame with the normal app on success or a truthful
  recovery frame on failure;
- reject candidate promotion until the installed checksum, cold start, named
  interactive frame, no-fatal scan and screenshot are all sealed;
- preserve r60.78 and its blank-frame screenshot as rejected evidence.
