# UAW C30T YouTube handoff focused-suite signed-in setup omission — 13 August 2026

The first handoff-focused suite omitted
`apps/mobile/test/ui_v2_social_continuous_batch_test.dart`. The authoritative
59-file manifest then found that its YouTube channel-status test supplied a
signed-in OTP gateway but never started `JourneySession`. The actor was
therefore signed out while the test asserted the retired direct-route behavior.

The omission was registered before retry. The accepted manifest owner is added
to the focused partition, and the signed-in routing case must explicitly start
and assert the session before tapping. Signed-out behavior remains covered by
the dedicated account-state and Screen 03 handoff tests.
