# REG3104 — Flutter rewrote local.properties escaping

- Date: 2026-08-21
- Status: registered before lifecycle repair

The successor Android audit test found that Flutter/Gradle regenerated ignored
`android/local.properties` with ordinary Windows drive/path separators after a
prior lint-clean normalization. The focused product tests passed; only the
transient-file assertion failed. No APK or device action followed.

Prevention: do not treat generated local properties as durable source. Add an
exact pre-`lintRelease` normalizer task and gate that task's presence; allow
Flutter to regenerate the local file outside lint execution.
