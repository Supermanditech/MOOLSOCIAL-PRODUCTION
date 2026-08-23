# C24B shared service-home and accessibility primitives preselection

C24B is the smallest shared runtime ticket required before any feature home changes. It introduces one reusable service-home component/token owner and repairs the already device-proven Android tap-action regression in the existing Mool launcher, Home Chat, family and direct-action semantic owners.

Reuse search found `MoolSpacing`, `MoolRadii`, `MoolMotion`, `MoolCardSurface`, `MoolHomeHubFamilyRow` and the global navigation owner. No suitable shared search/section/service-card hierarchy exists. One `mool_service_home.dart` owner is therefore necessary to prevent separate Eat, Ride, Book and Work component copies. It creates no screen, route, backend owner, provider integration, business state or subaction.

Robustness coverage includes 320/390/430 widths, 1.4 text scaling, 52-pixel search, minimum 44-pixel actions, finite/reduced motion, theme-safe contrast and direct `SemanticsAction.tap`. Focused primitive tests and strengthened C23 Home semantic tests must pass before C24C can be selected.

Social and Buy visual/runtime owners are excluded. Build, install, device mutation, external services, credentials, messages/calls, funds and Production remain closed.
