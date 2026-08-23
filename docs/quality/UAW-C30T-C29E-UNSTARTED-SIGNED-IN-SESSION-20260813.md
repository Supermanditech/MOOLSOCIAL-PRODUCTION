# C30T C29E unstarted signed-in session — 2026-08-13

The C29E test creates `JourneySession(otpGateway: ReviewOtpGateway(signedIn: true))` but does not call `start()` before it taps Create. It then expects `social-v2-create-workbench`. The product correctly refuses to infer an authenticated lifecycle from constructor configuration alone. The test must start and prove the session before mounting the authenticated mutation journey.

## Resolution

The test now awaits `journey.start()` and proves `journey.isAuthenticated` before mounting Social. Its full YouTube/Home/Shorts/Create/Feed hosting-separation journey passes without changing product authentication behavior.
