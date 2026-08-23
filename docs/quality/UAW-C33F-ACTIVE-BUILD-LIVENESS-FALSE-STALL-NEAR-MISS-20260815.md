# UAW-C33F active-build liveness false-stall near miss

Date: 2026-08-15

## Preserved observation

During the one authorized r60.49 AAB build, the C33F machine state remained `release_config_manifest_and_single_AAB_build_in_progress_authority_consumed`, the transient release files were already absent, and the redirected Flutter build log remained zero bytes for several minutes. The founder launcher, Dart process and direct Java child existed, but the direct Java child showed little CPU use.

No retry, second launcher, process termination, state repair, upload, Play action or OPPO action was attempted. A wider process inventory proved a Gradle Java worker outside the direct launcher descendant tree was actively compiling, with a 131.30 CPU-second increase during a 20-second observation. The build then produced the sealed AAB and provenance normally.

## Prevention

An unchanged in-progress state, erased transient inputs, or a buffered zero-byte log is not sufficient evidence of a failed or stalled build. When single-build authority is consumed, inspect only sanitized state, artifact metadata, process names and bounded CPU deltas across the full relevant tool set. Never restart, repair state or spend another authority while any build worker is active. Wait for wrapper exit and the terminal machine state.
