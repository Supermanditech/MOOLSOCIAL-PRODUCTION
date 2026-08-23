# UAW C33J FIX1 foreground email-link return handoff preselection

Ticket: `UAW-C33J-FIX1-FOREGROUND-EMAIL-LINK-RETURN-HANDOFF`

C33J qualifies the native UI and cold-start email-link entry path, but read-only lifecycle inventory found no `didPushRouteInformation` owner. A link opened while the app process remains active could therefore reach the router as an unrelated external location instead of the email-link state machine.

The smallest correction reuses the existing `MoolSocialApp` `WidgetsBindingObserver`, `JourneySession.prepareEmailLinkReturn`, current router and Screen 03 v5. One asynchronous route-information callback consumes only gateway-recognized email links, routes completed authentication to `readyRoute()`, and routes a missing-email return to `/sign-in`. Unrecognized route information remains unhandled.

No screen, product route, backend owner, Android manifest, Hosting/domain, Firebase provider or live-email change is included. No real action link is used, logged or persisted. Focused tests use only the deterministic review gateway's non-credential marker.
