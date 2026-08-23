# UAW-C34P FIX5 r60.80 Firebase-bootstrap qualification

## Exact diagnosis and fix

r60.79 reached the update-required frame by 1.635 seconds. Exact runtime-define
and sideload-mode gates ruled out the release precheck; the remaining immediate
stage was Firebase initialization with explicit Dart options while live Android
was already configured from the refreshed native `google-services.json`.

r60.80 uses native Android Firebase configuration for live Android and retains
explicit options for emulator and non-Android paths. Every pre-app stage emits
only a sanitized begin/pass/fail identifier.

## Source qualification

- focused startup/auth: 36/36;
- two affected cycles: 21 suites, 198/198 each;
- Flutter analysis: no issues;
- source files: 287;
- source SHA-256:
  `407CC791F27EF703D5E7B012D921AB153F5BDE0886DFB66238F30069FF7A7758`.

## Strengthened machine discipline

The public-auth APK profile now requires 17 prebuild gates, including
`bootstrap-stage-diagnosis` and `device-cold-start-policy`. After installation,
authentication testing remains blocked until the checksum-matched APK reaches
a named Flutter-owned cold-start frame with zero fatal/ANR markers and retained
screenshot evidence.

## Held boundaries

- no OPPO install without later action-time confirmation;
- no private login, email or SMS action;
- no Play upload or Production promotion.

## Built artifact

- bytes: 101,589,372;
- SHA-256: `09A826348D170BE90F78D8E6EF2594C4756957C51D50717C3420C3A4B11E8E3F`;
- signature, signer, package, version and provenance: qualified;
- debuggable: false;
- in-place update possible without uninstall or data clear;
- authentication testing remains blocked until the installed cold-start stage
  receipt passes.
