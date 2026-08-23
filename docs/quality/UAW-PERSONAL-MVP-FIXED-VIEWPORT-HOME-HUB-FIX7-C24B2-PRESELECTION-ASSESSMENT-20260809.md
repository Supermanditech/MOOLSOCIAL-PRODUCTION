# C24B2 fixed-viewport Home hub preselection

C24B2 replaces only the current Home presentation owner. It reuses `PersonalMoolRootV2`, the existing six-family/direct-action catalogue, C24B design/accessibility tokens, route callbacks, Chat and Back behavior. The family/action data is consolidated in the existing global-navigation source so C24B3 can reuse it without a second catalogue.

No new screen, route, backend owner, provider integration, persistent business state or subaction is necessary. The current expanded family-row primitive remains available for accepted tests but is no longer the Home runtime layout.

The fixed viewport contains one top Chat action, a three-by-two main-family grid and a two-column selected-family action panel. It contains no scrollable widget owner and no MoolSocial/Home/Your Mool/welcome/area/decorative header content. Family selection stays in place; a direct action opens the existing route. Tests cover 320/390/430 widths, 1.4 text scale, all six family meanings, two-to-four action counts, no overflow, tap semantics, Back/Chat and reduced motion.

Social/Buy business content is not mutated. Build, install, device, backend, external service, credentials, messages/calls, funds and Production remain closed.
