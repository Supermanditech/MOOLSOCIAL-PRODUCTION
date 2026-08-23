# C30O Computer Use extension-store navigation URL-confidence stop rejection

- Date: 2026-08-12
- Scope: opening the founder-approved official ChatGPT Chrome extension listing
- Result: Computer Use stopped before safe browser navigation could be verified

## Mistake

After action-time founder confirmation, Computer Use was asked to open a new Chrome tab for the official extension. The safety layer stopped the turn because it could not determine the current browser URL with sufficient confidence.

## Root cause

The Windows-control surface could not establish URL provenance for the target Chrome window at the point of navigation, so the policy-safe navigation precondition was unavailable.

## Permanent prevention

Do not retry extension-store navigation through Computer Use. The founder manually opened the exact official listing from the bundled Browser plugin metadata and installed the extension. Resume only through the Browser skill's Chrome extension connection and verify the exact existing Play tab before browser action.

## Safety outcome

The assistant did not bypass the stop, did not install software through automation, and did not change Play, Firebase, the device, or repository source. The founder later attested that the official extension installation completed manually.
