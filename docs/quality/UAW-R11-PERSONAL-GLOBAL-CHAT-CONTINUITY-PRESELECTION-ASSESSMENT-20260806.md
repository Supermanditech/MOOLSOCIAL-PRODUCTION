# UAW-R11 Personal global Chat continuity preselection assessment

Date: 6 August 2026
Ticket: `UAW-R11-PERSONAL-GLOBAL-CHAT-CONTINUITY`
Classification: `mvp_required`

## Customer outcome and reason

A Personal user can open the authoritative in-app MoolChat entry from Personal
Mool or any shared action root and return to the exact permitted origin. Global
Chat continuity is required launch navigation and must not be replaced by an
external messaging app.

## Reuse and smallest complete scope

- Reuse the existing `PersonalMoolRootV2` and `MvpActionChoiceRootV2` Chat
  controls.
- Reuse `/app/chat/inbox`, `ChatInboxScreen`, `ChatSession`, `chatRoute` and
  `chatGoBack` unchanged.
- Reuse the consolidated router's exact return values for Mool, Eat, Ride,
  Book and Work.
- Add only a versioned continuity contract and focused production-router
  acceptance tests.
- Reuse existing `chat_flow_test.dart` and vertical journey-context return
  evidence for deeper direct/shared contexts.

Necessity proof: all required production owners and return-route wiring already
exist. Runtime work would duplicate Chat ownership or broaden the ticket; exact
acceptance evidence is the only necessary change.

## Explicit exclusions

- No new Chat screen, route, session, controller, model or backend owner.
- No message, conversation, notification, calling, attachment, presence,
  delivery-state or support behavior change.
- No WhatsApp or other external messenger as an authoritative record.
- No arbitrary/non-app return target and no legacy-route containment work;
  UAW-R12 owns removed-route containment.
- No build, install, OPPO mutation, external-service action, credentials,
  commit, push, deploy, promotion or FIX7/baseline change.

## Dependencies, approval and verification

Dependencies: founder-preauthorized batch, completed R03/R06-R10 shared
navigation, existing Chat route owner and parent Chat contracts, native Flutter
directive and 60–75 day reuse lock.

Verification: execution gate; exact human/machine continuity contract; focused
production-router tests across Mool/Eat/Ride/Book/Work; full analyze; existing
Chat and shared-root regressions; protected-state diff checks; no build/device
action.

Estimated batch impact: **0 days**, within the locked delivery window.
