# UAW C30T Chat retry busy-message-loss finding — 2026-08-13

## Finding

The production Chat retry state machine removed a failed message and its stored
retry identity before asking `send` to start. When any Chat write was already
pending, `send` returned `false` immediately, leaving the original failed
message absent even though no retry transport occurred.

The message-level Retry control also remained enabled while the shared Chat
session was busy.

## Bounded correction

- Reject `retry` before changing message, attachment, or retry-key state when
  Chat is busy.
- Disable the Retry control while Chat is busy.
- Keep the original failed message and idempotency identity intact.
- Prove a rejected busy retry performs no extra provider call.

No backend, provider, live Chat, device, build, Play, Hosting, or communication
action is part of this correction.

## Verification

The production gateway and full Chat flow focused corpus passed 10 tests with
zero failures. The exact log is
`artifacts/quality/uaw-personal-mvp-social-play-internal-live-read-recovery-c30t-continuous-audit-20260813-03/chat-retry-busy-focused-tests.log`
with SHA-256
`A199804135CF85D357B7EC6BB6CD9EEC0402A186897608C65FB2B8E5970D0132`.

A release AAB remains separately founder-gated.
