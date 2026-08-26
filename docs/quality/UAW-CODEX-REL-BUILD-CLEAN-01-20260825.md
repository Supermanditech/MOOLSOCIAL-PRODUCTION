# UAW-CODEX-REL-BUILD-CLEAN-01-20260825

Founder date: 25 August 2026 IST  
Parent: `UAW-CODEX-SOCIAL-RUNTIME-CONTINUATION-20260825`  
Runtime ticket: `REL-BUILD-CLEAN-01`

## Outcome

Supported Flutter test/build entrypoints may refresh tracked support files
internally, but every command returns them byte-for-byte to their exact
pre-command state on success, failure or exception.

Classification: `mvp_required` because generated support dirt can contaminate
an atomic ticket, invalidate source seals and make a successor APK nonreproducible.

## Scope

- Guard exactly package_config.json, package_graph.json,
  .flutter-plugins-dependencies and GeneratedPluginRegistrant.java.
- Preserve pre-existing bytes, not HEAD bytes.
- Reject missing, untracked, escaped, duplicate or reparse owners.
- Serialize by a worktree-derived named mutex.
- Restore and byte-verify in finally while returning one exact child exit.
- Integrate the guard into the supported device-review build wrapper.
- Prove mutation, deletion, nonzero exit, outside-file safety, concurrency and
  one real focused Flutter test without building an APK.

## Exclusions

- No APK/AAB build, install, Play action, dependency change or generated-file
  commit.
- No Cursor, UI, backend, provider, cloud, account or private-data change.

## Verification

- Dual script AST parse and fixture matrix.
- Real guarded Flutter test and scalar exit assertion.
- Exact four-file before/after SHA equality and zero support dirt.
- Static build-wrapper integration and forbidden-destructive-command audit.
