# C30T Windows rg wildcard path recurrence

Date: 2026-08-13

A YouTube player audit passed `apps/mobile/test/social_v2_youtube*` and `apps/mobile/test/youtube_embedded*` as Windows path arguments. `rg` printed partial matches from valid owners, then rejected both wildcard paths and exited nonzero.

Permanent prevention: pass only existing directory roots and use `--glob` for filename filtering. Partial output from an invalid-path command is not complete audit evidence.
