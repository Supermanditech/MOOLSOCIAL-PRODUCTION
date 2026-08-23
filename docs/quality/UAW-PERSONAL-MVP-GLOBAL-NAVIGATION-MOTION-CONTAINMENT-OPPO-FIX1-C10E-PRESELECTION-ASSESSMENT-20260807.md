# C10E pre-ticket robustness, reuse and scope assessment

- Ticket: `UAW-PERSONAL-MVP-GLOBAL-NAVIGATION-MOTION-CONTAINMENT-OPPO-FIX1-C10E`
- Contract: `C10E-V1-20260807`
- Classification: `mvp_required`
- Settled manifest: `config/uaw-personal-mvp-global-navigation-motion-containment-oppo-fix1-c10e-ticket.json`
- Manifest SHA-256: `C8EE732C762EAD7F32DBB3B5169EE898E819801CFCD013C35FD8DD5C737CA5E7`

## Customer outcome and necessity

Every supported main destination must feel like one MoolSocial app: the bottom
navigation keeps one geometry and meaning, the active destination remains
truthful, destination changes use short directional motion, and Back restores
the exact live owner. The founder's OPPO replay confirmed that the installed
r60.9 still cold-opens Workspace and changes to destination-owned rails, so
orientation and return remain launch-blocking regressions.

## Reuse and duplicate inventory

The implementation reuses `MoolGlobalNavigationV2`, `MoolOutcomeDock`,
`MoolMotion`, the existing GoRouter app-section owner and every existing
Eat/Ride/Book/Work/Chat/Buy session and route. The compiled source inventory
found the retired `EatBottomDock`, `RideBottomDock`, `BookBottomDock`,
`WorkBottomDock` and `_SharedDock` destination owners; they must be contained,
not duplicated. No new screen, named route, backend, provider, persistent
business-state owner or build family is necessary.

Disposition: reuse, configuration, test-only acceptance and bounded new
necessary work inside the shared navigation/motion policy and existing page
scaffolds. Local actions such as Order Food, Book Table, Bike, Auto, Cab,
Doctor, Salon, Earn Today and Workspace stay within destination content; they
never occupy the global rail.

## Smallest complete implementation

- one shared global dock on Mool, Social, Buy, Eat, Ride, Book, Work and Chat;
- selected root is disabled and semantic current state remains truthful;
- 240 ms finite directional main-destination transition using existing motion
  curves, with zero non-essential translation when animations are disabled;
- content-depth Back only; no top Back on a top-level root;
- static source rejection of retired destination-owned rail classes/keys;
- two complete affected host regression cycles before any candidate gate.

## Explicit exclusions and dependencies

No locked Screen 01–03 or accepted Social/Buy content redesign, new feature,
backend/provider/payment work, credential access, live message/call, Production
write, deployment, commit, push or promotion is included. No APK build or OPPO
install is currently authorized: the consumed r60.9 machine state must remain
preserved until host qualification is complete and one unique successor is
separately pinned and machine-authorized.

The work reuses the completed C10A–C10D host contracts and fits within one
engineering day without changing the 60–75-day robust-MVP window.

## Qualification plan

Focused router/widget tests cover stable geometry, every main-root switch,
direction, interruption, exact Back, compact/140% layouts and reduced motion.
Static gates reject every retired owner/key and customer-copy regression. Two
complete affected host cycles, analysis, locked-screen, scope, delivery and
permanent-regression gates must pass. A later machine-authorized candidate must
match its checksum/runtime marker and be replayed on OPPO from fresh launch
through Mool, Social, Buy, Eat, Ride, Book, Work and Chat before founder review.
