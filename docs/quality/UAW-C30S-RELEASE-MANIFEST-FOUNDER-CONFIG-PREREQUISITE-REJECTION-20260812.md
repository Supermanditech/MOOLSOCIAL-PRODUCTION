# C30S release manifest founder-config prerequisite rejection

Date: 2026-08-12

After adopting the official Google Services and Crashlytics plugin pair,
`processReleaseMainManifest` was invoked before the founder-controlled
transient Google Services configuration existed. It exited `1`. APK and AAB
sentinels were unchanged. The merged manifest present on disk was a stale
C30Q output and is explicitly rejected as C30S evidence.

Before founder input, C30S proves fail-closed task registration and static
source contracts only. The founder launcher creates the transient release
configuration; the single build wrapper then requires successful fresh release
configuration/manifest output, seals its hash, and the launcher removes the
configuration afterward. A nonzero task or stale output can never qualify.
