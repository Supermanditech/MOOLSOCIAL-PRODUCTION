# UAW-C33F postbuild gate prerelease machine-state deadlock

Date: 2026-08-15

## Preserved failure

The one authorized r60.49 wrapper completed the AAB, proved its payload and provenance, wrote `single_release_AAB_succeeded_authority_consumed`, and then invoked the mandatory C33F `postbuild` gate. The gate rejected its own wrapper-produced success state with `machine state does not match live-readiness and source-cycle qualification`.

The sealed AAB and provenance remain preserved. Build result count is one, build authority is consumed, upload/install/device counts remain zero, and no Play, OPPO, provider, email or quota action occurred. No hidden value was read or stored by Codex.

## Root cause and prevention

The C33F gate calculates one prerelease machine state only from readiness facts and source cycles before it branches on `Phase`. It therefore requires `source_and_live_readiness_qualified_founder_secret_prompt_required` during `postbuild`, even though the wrapper must transition to `single_release_AAB_succeeded_authority_consumed` before invoking that phase.

Make expected machine state phase-aware and prove the exact wrapper-produced state for `postbuild` and `preupload`. Negative tests must reject prerelease, in-progress, upload and install states at the wrong phase.
