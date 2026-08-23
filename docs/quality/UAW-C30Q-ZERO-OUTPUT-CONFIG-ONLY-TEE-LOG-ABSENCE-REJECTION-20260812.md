# C30Q zero-output config-only Tee log absence rejection

The corrected release config-only command succeeded, left `pubspec.yaml` and
`pubspec.lock` unchanged, changed no APK, and regenerated a release registrant
without `IntegrationTestPlugin`. It emitted no pipeline objects, so
`Tee-Object` did not create the expected empty config-only log. The qualifier
then failed while hashing that absent evidence file.

No AAB, secret prompt or build-authority mutation occurred. The partial
`source-aggregate-manifest.txt` written before the hash step is rejected and
preserved unchanged.

Prevention: precreate every native log as an empty UTF-8 file before invoking
the pipeline so a successful zero-output command still has hashable evidence.
Use new `1r3` cycle logs and a distinct accepted source manifest; never
overwrite the rejected logs or partial manifest.
