# UAW C33J foreground email-link return missing lifecycle owner

- Finding: `REG-20260815-2498-C33J-FOREGROUND-EMAIL-LINK-RETURN-MISSING-LIFECYCLE-OWNER`
- Product risk: cold-start parsing exists in `main.dart`, but no active-process route-information observer forwards a newly opened email link to `JourneySession`.
- User impact: same-device sign-in can dead-end when the email is opened while MoolSocial remains alive.
- Required correction: `UAW-C33J-FIX1-FOREGROUND-EMAIL-LINK-RETURN-HANDOFF`.
- Boundary: source and tests only; no App Link/provider/Hosting/email/build/device action.
