# C30T Social/YouTube search used a nonexistent optional path

Date: 2026-08-13
Candidate: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`

The bounded release-surface search included `apps/mobile/lib/app.dart`, a conventional filename that is absent from this repository. Ripgrep returned exit 2 after printing matches from the valid paths. No product, device, provider, AAB, Play, Firebase, or external state changed.

Permanent rule: discover exact mobile entrypoints with `rg --files apps/mobile/lib` or `Test-Path`, search only existing paths, and reject exit 2 even if partial matches look useful. The partial output is orientation only and is not accepted as completed audit evidence.
