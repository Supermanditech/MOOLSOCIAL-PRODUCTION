# REG-20260812-1385 — C30H Social Home stable-readiness early assertion rejection

- Candidate: `UAW-PERSONAL-MVP-SOCIAL-WATCH-RETURN-OPPO-REVIEW-C30H`
- Phase: OPPO live provider replay
- Failure: The live `Open Social` action succeeded and exported `Home, current, YouTube`, but the fixed wait ended while the real provider was still loading, before `Search YouTube` was exported.
- Rejection: `16-social-home-restored.*` proves only route arrival/loading, not stable Home readiness.
- Permanent prevention: After a truthfully successful route action, use bounded no-touch hierarchy polling that accepts the explicit loading state and stops only when the stable required action set appears or a bounded timeout/error state is captured. Do not repeat the route action.
- Protected state: No repeated navigation action, rebuild, reinstall, uninstall, data clear, downgrade or deployment occurred.
