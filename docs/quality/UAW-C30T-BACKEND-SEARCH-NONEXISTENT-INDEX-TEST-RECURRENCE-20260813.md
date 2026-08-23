# C30T backend search guessed a nonexistent index test path

Date: 2026-08-13
Candidate: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`

The YouTube capability audit passed `backend/functions/src/index.test.ts` to ripgrep even though that file is absent. This repeated the previously registered nonexistent-path diagnostic class. Ripgrep returned exit 2; partial output is not accepted as completed evidence. No application, provider, device, AAB, Play, Firebase, or communication state changed.

Permanent rule: generate the backend search set from `rg --files backend/functions/src`, filter the discovered paths, and pass only those exact files. Never hand-type an optional backend test filename. Any ripgrep exit 2 invalidates the diagnostic.
