# REG-20260822-3146 — FIX8 MVP robustness scalar transcription

Date: 22 August 2026

State: registered; first two array lines retained, third unchanged

The third one-line robustness substitution was rejected because the retyped
current X coverage string did not preserve its exact punctuation and underscore
layout. The two previously accepted substitutions remain parsed; the rejected
third line did not change.

No runtime source, tests, build, APK, OPPO, provider, account, email/SMS, Play
or cloud state changed.

Root cause: even the smaller method still manually transcribed a long current
scalar instead of copying the parsed live value exactly.

Prevention: project the remaining current array values as indexed scalars,
copy each returned scalar exactly into its one-line patch and verify the indexed
replacement immediately. Do not infer punctuation from prose.
