# C30T broad apply-patch context rejection

- Date: 2026-08-13
- Repository: `C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION`
- Scope: YouTube Home recovery-control implementation

The first refactor patch combined multiple branches of `_buildVideos()` and included a context fragment that did not exactly match the current dirty source. `apply_patch` rejected the edit atomically, so no source file changed.

The retry must use the exact current bounded source and several small hunks: first reorder the existing search/watch branches, then wrap each status branch, and finally introduce the shared Home frame. Broad inferred context is prohibited for the retry.
