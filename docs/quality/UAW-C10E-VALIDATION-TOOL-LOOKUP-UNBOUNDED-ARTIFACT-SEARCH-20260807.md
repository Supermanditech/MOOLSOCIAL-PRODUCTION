# C10E validation-tool lookup unbounded artifact search

- Registry: `REG-20260807-235-C10E-VALIDATION-TOOL-LOOKUP-UNBOUNDED-ARTIFACT-SEARCH`
- State: resolved; permanent gate active.

A validation-tool lookup searched the full retained artifact tree for command
examples and timed out before returning a usable result. It made no repository,
APK-state or device change.

Validation now uses the exact SDK directory already recorded in the scoped
`android/local.properties` file and deterministic build-tools paths. Future
documentation searches exclude binary/large artifact trees or use narrow file
globs and known candidate evidence directories.
