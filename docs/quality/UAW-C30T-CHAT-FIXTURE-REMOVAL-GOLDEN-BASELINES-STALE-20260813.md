# C30T Chat fixture-removal golden baselines stale — 2026-08-13

The expanded 49-file audit proved that all four Chat phone goldens still encode the now-forbidden review fixture conversations. Pixel differences were 49.84% for inbox and 28.71% for order support, with business and people also failing. The replacement states must be captured and inspected at 412×915 before any golden is rebaselined. This is test debt from the authorized real-Chat correction, not authority to restore fixture data.

## Resolution

`chat_visual_golden_test.dart` now constructs `ChatSession.production()` with a deterministic `ChatGateway`, not the review-fixture constructor. Five new C30T-named baselines cover the authenticated empty inbox, provider-unavailable inbox with retry, and provider-owned support, business and people threads. The historical July images remain untouched. All five new 412×915 images were inspected after generation and contain only truthful empty/error/provider-returned content with no call, video, attachment, order, quote or payment controls.
