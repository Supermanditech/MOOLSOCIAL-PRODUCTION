# C26D Social and Shop navigation conformance preselection

Classification: `mvp_required`

## Customer outcome

Social and Shop retain their accepted content and direct action routes while receiving the completed C26B transparent rail and C26C embedded Mool switcher through the existing shared destination owner.

## Scope, reuse and duplication decision

- Runtime implementation disposition: reuse only; no runtime mutation authorized.
- Existing owners: `SocialUniversalV2`, `Screen04ContextTabs`, `BuyV2Screen`, `BuyV2Session` and `MoolDestinationNavigationV2`.
- No new screen, route, subaction, session, state or backend owner.
- Existing accepted Social and Buy content seals remain authoritative.

## Focused proof

- Social: root, Shorts, Videos, Feed and Create remain direct.
- Shop: root, Products, Wholesale and Orders remain direct.
- Both families expose the same Mool switcher and transparent non-scrolling bottom rail.
- No old strap, capsule, themed panel or horizontal scroll is rendered.

Build, installation and external writes remain unauthorized in C26D.
