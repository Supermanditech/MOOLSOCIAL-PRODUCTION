# UAW C30T regression-gate evidence-path schema second rejection — 2026-08-13

After correcting REG-1810, the next gate run exposed the same schema mistake in
REG-1809: `flutter analyze` was a command label rather than a repository path.
The first repair inspected only the reported entry instead of auditing every
new entry added by the same patch. No formatter, analyzer retry or build ran.
All new entries are now checked together before the next attempt.
