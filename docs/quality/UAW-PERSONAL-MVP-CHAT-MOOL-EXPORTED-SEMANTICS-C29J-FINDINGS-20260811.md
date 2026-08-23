# C29J bounded founder findings

## Customer outcome

Chat keeps the founder-approved common Mool switcher, and its exported Android target remains at least 44 logical pixels on OPPO without adding a tap, moving the switcher away from one-handed reach or changing other accepted navigation.

## Reuse and duplicate assessment

- Exact runtime owner: `apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart`.
- Exact Chat consumer: `apps/mobile/lib/features/chat/widgets/chat_widgets.dart`; it correctly reuses `MoolGlobalNavigationV2` and needs no route-specific fork.
- Existing reusable geometry owner: `moolAndroidExportedSemanticsClearance`.
- Existing protected test owner: `apps/mobile/test/ui_v2/universal/mool_android_navigation_viewport_c28b_test.dart`.
- No new screen, route, navigation system, backend owner, provider call or credential access is necessary.

The defect is not the switcher rows or the Social destination dock. The standalone non-compact global launcher lacks the clearance already applied by `MoolDestinationNavigationV2`; compact placement must not receive the clearance twice.

## MVP and authority assessment

This is MVP-supporting accessibility and tap-reliability containment required by the permanent C28D rejection. C29J authorizes the smallest shared Flutter and protected-test correction plus two fresh host cycles. Build, install, backend, external-service, credential, reference, HTML, deployment and promotion authority stay closed. A separately registered and freshly qualified OPPO successor is required after C29J host completion.
