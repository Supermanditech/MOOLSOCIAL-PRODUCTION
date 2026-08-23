# C26F local-history Back still mutated Medicine state

## Observation

Care Medicine remained on the Buy screen after first Back, but its Care Medicine rail key disappeared. The destination's internal Back owner had still reacted.

## Cause

Local history protected route identity but did not stop the failed-pop notification from reaching page-level PopScope state handlers.

## Permanent prevention

- Consume platform Back at the router dispatcher through `BackButtonListener` while Mool is open.
- Return `true` only after the switcher close is initiated/completed.
- Retain local history as route-local fallback and remove it on every non-Back dismissal.
- Verify the exact `care-local-tab-medicine` state survives first Back.

## Resolution state

Fix active; C26F, host and APK qualification remain blocked until the exact cross-owned state regression passes.
