# Global Mool navigation C05 preselection assessment

Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C05-CHAT-SHARED-RETURN`
Classification: `mvp_required`
State: `PASSED_REUSE_AND_ROBUSTNESS_CHECKPOINT`

## Customer outcome

From a filtered Chat inbox, an exact Chat thread/composer, and Shared Activity,
Account, Spaces or Controls, tapping Mool pushes the existing stable Personal
hub. Header and Android system Back from the hub restore the exact unchanged
origin. Chat filter, search, draft, reply and attachment state remain owned by
the existing mounted Chat owners; Shared session and visible state are not
recreated. Neither Chat nor Shared routes through Social.

## Reuse and duplicate search

The inventory covers `ChatInboxScreen`, `ChatThreadScreen`, their existing text
controllers, `ChatSession.selectedFilter`, `pendingAttachment`, `replyingTo`,
the production Chat routes and return query, `SharedHubScreen`, `_SharedDock`,
`SharedSession`, all seven shared route projections, `PersonalMoolRootV2` and
GoRouter push/pop history. The parent audit and C05 source inventory prove no
new screen, route, session, service, store, backend, provider, draft store or
persistent product state is required.

Implementation dispositions: `reuse`, `configuration`,
`thin_policy_adapter`, `test_only_acceptance`.

New screens: none. New named routes: none. New backend/provider/message/call
owners: none. Timeline impact: one day maximum, within the founder-locked
60–75-day window.

## Robustness

Production-router tests cover filtered inbox Mool/Back, thread Mool/Back with
unsent text plus reply and attachment state, repeated transitions, Shared
Activity/Identity/Ask/Files/Security/Spaces/Controls exact return, direct hub
Back behavior, compact/scaled text, semantics and minimum tap targets. Static
gates reject Chat `go('/app/mool')` transitions and the Shared
`go('/app/social')` alias. Existing message send, call/video, attachment,
provider, account/workspace and persistence owners remain unchanged.

## Exclusions and dependencies

No new Chat or Shared presentation/state owner; no message send, call/video,
attachment, provider, account/workspace, backend or persistence behavior; no
golden or accepted-reference change; no build/install; no credentials,
payments/funds, live provider message/call, Production, commit, push, deploy,
promotion, screenbook mutation, OPPO uninstall/data clear/downgrade or
rejected-evidence mutation. Dependencies are completed C01-C04, founder
authorization, the locked global 22-case contract and preserved r60.6
rejection.

The clean-at-HEAD Screen 01 hash mismatch recorded by REG-045 is a pre-existing
release blocker. C05 must capture it before and after implementation, prove a
zero protected-file diff and never mutate the accepted screen or lock.
