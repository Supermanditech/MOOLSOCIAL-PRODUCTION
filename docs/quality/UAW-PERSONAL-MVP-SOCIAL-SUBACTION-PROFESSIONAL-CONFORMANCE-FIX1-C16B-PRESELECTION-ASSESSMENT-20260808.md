# C16B Social sub-action conformance preselection assessment

## Selected ticket

- Ticket: `UAW-PERSONAL-MVP-SOCIAL-SUBACTION-PROFESSIONAL-CONFORMANCE-FIX1-C16B`.
- Classification: `mvp_required`.
- Parent authority:
  `config/uaw-personal-mvp-global-subaction-professional-design-system-fix1-c16-ticket.json`.
- Predecessor evidence: Social Shorts, Videos, Feed and Create are all captured
  in the completed r60.15 OPPO audit before design selection.

## Customer outcome

Social customers retain one-tap Shorts, Videos, Feed and Create while those
actions use the same professional compact tokens, selected state, semantics and
finite/reduced motion contract as every other main-action family.

## Reuse and duplicate decision

- Reuse `Screen04ContextTabs`, existing `Screen04Choice` state/callbacks and all
  Social route/content/provider owners.
- Reuse the qualified C16A `MoolLocalNavigationRail`,
  `MoolLocalNavigationAction` and `MoolLocalNavigationTokens` owners.
- Remove the duplicate `_TrackingRailRibbon`, `_TrackingRailRibbonState`,
  `_RailAction` and `_RailIdentityLine` renderers after the shared owner is
  connected.
- Preserve YouTube provider attribution for Shorts/Videos through the shared
  optional icon-asset and semantic-label fields.
- Duplicate search is complete. No new screen, route, action, provider,
  backend, service or persistent state owner is necessary.

## Minimum complete scope

1. Map the existing four Social choices to shared actions and their existing
   direct callbacks.
2. Keep all targets at least 44x44 and selected actions inert.
3. Preserve provider attribution and truthful `YouTube Shorts` /
   `YouTube Videos` semantics.
4. Remove the bespoke Social rail implementation so only the C16A owner renders
   the sub-action family.
5. Prove compact and large-text geometry, one-tap state changes, uniform tokens,
   finite motion, immediate reduced motion and unchanged Social content owners.

## Explicit exclusions

- No Social route, tab inventory, feed, composer, YouTube integration, provider
  asset, copy, search, promotion or commercial-logic change.
- No action added for symmetry and no menu, modal, palette or extra tap.
- No screenbook write or HTML-to-Flutter copy.
- No build, install, credentials, message/call, payment/fund, Production,
  commit, push, deploy or promotion authority.

## Gate plan

- C16B static duplicate-owner and provider-preservation gate.
- Social focused widget coverage at 320px / 140% text and reduced motion.
- C16A owner suite, C11 placement/motion suite and Social affected tests.
- Regression memory, MVP scope and delivery-discipline gates.
