# REG3097 — Android lintRelease found 6 errors and 2 warnings

- Date: 2026-08-21
- Status: registered; complete classification pending

The comprehensive Android audit completed release Java compilation with the
Firebase Core registrant present and integration-test registration absent.
`lintRelease` then failed with 6 errors and 2 warnings. The first error reports
that manifest class `com.facebook.FacebookActivity` is missing from the project
or release libraries, indicating an incomplete native Facebook configuration.
No APK build, install or external action followed.

Prevention: treat `lintRelease` as a mandatory pre-APK gate, classify every
reported item, fix source/dependency configuration instead of creating a lint
baseline, and rerun until zero errors.
