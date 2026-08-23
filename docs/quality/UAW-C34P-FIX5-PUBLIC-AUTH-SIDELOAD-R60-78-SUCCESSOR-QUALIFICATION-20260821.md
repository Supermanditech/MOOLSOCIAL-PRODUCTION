# UAW-C34P FIX5 public-auth sideload r60.78 successor qualification

## Outcome

r60.78 is a distinct release successor for the REG3083 startup-mode repair.
It may be built once with the already validated local signing environment. The
installed r60.77 APK, checksum and first-launch rejection remain immutable.

## Source evidence

- Flutter analysis: no issues;
- focused startup/auth tests: 34/34;
- two identical affected cycles: 21 suites, 196/196 each;
- source manifest: 287 files;
- source SHA-256:
  `A898E58C55CD71C72E3A37A7C095404D0FC81DC7C8FA4C23B68C96027AD3E9A8`.

## Regression prevention

Live device review now accepts only one of two exact profiles:

1. existing YouTube public review with private development proof; or
2. public-auth sideload with both the explicit sideload fact and local signing
   qualification.

Missing either sideload fact, using the sideload flag outside device review,
or selecting an unqualified live device-review mode remains fail-closed.

## Held boundaries

- no Play upload;
- no Production promotion;
- no private login, real email or real SMS without later confirmation;
- no r60.78 OPPO update until its artifact is qualified and action-time
  confirmation is recorded.

## Built artifact

- bytes: 101,507,452;
- SHA-256: `3924E09FF7613F5B10B998D70DFD5D5E7A5F04113B847C43C0759E0F71CC614C`;
- APK signature and provenance: qualified;
- signer matches the installed upload-key predecessor: yes;
- package/version: `com.moolsocial.app`, `1.0.0-r60.78+2026082178`;
- debuggable: false;
- in-place update: possible without uninstall or data clear;
- Play upload: not performed.
