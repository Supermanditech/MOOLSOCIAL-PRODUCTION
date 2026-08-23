# UAW C10 regression gate command-label path failure

## Incident

REG-164 placed the human-readable command name `flutter analyze` in its
`gates` array. The regression-memory checker correctly rejected the entry
because every gate must resolve to a repository-relative file.

## Prevention

Registry gate and evidence values are existence-verified paths only. Commands
are described in prose, while their durable enforcement is linked through the
real configuration or script path. REG-164 now references
`apps/mobile/analysis_options.yaml` and the memory checker.

No runtime, build or device state changed.
