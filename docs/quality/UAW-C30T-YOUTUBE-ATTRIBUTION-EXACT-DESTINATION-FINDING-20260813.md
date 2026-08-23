# C30T YouTube attribution exact-destination finding

Date: 2026-08-13

All current production attribution instances pass exact video or channel handlers, but `_YouTubeAttribution` allowed an omitted handler and silently opened generic YouTube Home. That fallback weakened the standard link/source integrity boundary and allowed future callers to expose an attribution control that did not lead to its represented content.

The attribution handler is now required and non-nullable, and the generic-home fallback is removed. Existing exact video, Short and channel URL builders and their user-visible launch failure handling are retained. No visual, provider, release or external state changes.
