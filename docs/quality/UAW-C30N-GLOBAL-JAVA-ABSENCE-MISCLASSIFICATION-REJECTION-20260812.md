# C30N global Java absence misclassification rejection

- ID: `REG-20260812-1473-C30N-GLOBAL-JAVA-ABSENCE-MISCLASSIFICATION-REJECTION`
- Date: 2026-08-12
- Scope: local read-only C30N host qualification
- Result: host summary rejected; no APK build, install, cloud, device or content mutation occurred

The first host summary treated a nonzero global `java -version` as fatal even
though the permanent registry already requires optional global Java absence to
be handled explicitly. C30N rejects the combined summary and resolves the Java
binary from Flutter's configured Android toolchain, without changing PATH or
installing a second runtime.
