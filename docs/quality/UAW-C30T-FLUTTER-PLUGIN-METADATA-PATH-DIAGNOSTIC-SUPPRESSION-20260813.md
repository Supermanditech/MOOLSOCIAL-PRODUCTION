# C30T Flutter plugin-metadata path diagnostic suppression

Date: 2026-08-13

The first registrant-classification command queried both the existing `apps/mobile/.flutter-plugins-dependencies` owner and a nonexistent repository-root alternative while suppressing diagnostics. It returned useful text but exited nonzero, so the combined command is not accepted as qualification evidence.

The corrected classification must query only the resolved mobile metadata file and retain command diagnostics. No dependency or generated registrant is modified by this correction.
