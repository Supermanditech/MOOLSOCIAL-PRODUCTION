# r60.21 founder device visual rejection and C23 successor direction

Date: 2026-08-09

## Installed candidate disposition

- Candidate: `UAW-PERSONAL-MVP-CAPSULE-SYSTEM-OPPO-QUALIFICATION-FIX5-C22H`
- Version: `1.0.0-r60.21` (`2026080921`)
- Installed/candidate SHA-256: `17AF5DC2353E7195A597555C88AA42B345AFFDA0EC160900B55B0D3E822691BE`
- First-install time preserved: `2026-08-04 02:51:59`
- Build/install count: one each; both authorities consumed
- Founder disposition: visually rejected, installed identity preserved until a separately qualified successor is authorized

The live evidence at
`artifacts/quality/uaw-personal-mvp-capsule-system-oppo-qualification-fix5-c22h-r60-21-20260809-01/16-current-ready.png`
shows the defect: four persistent Social subaction controls sit directly above
the persistent global Mool/Social/Buy/.../Chat rail. Both layers carry strong
outlines, icons, labels and selection treatments, so they compete with each
other and cover a large product-content zone.

## Founder-rejected findings

1. Two persistent navigation layers make the screen feel cluttered and unprofessional.
2. Main actions and subactions have nearly equal visual weight, weakening hierarchy.
3. The combined controls dominate the product/service screen and reduce content reachability.
4. Horizontal global-action discovery and a separate subaction row make the user manage navigation instead of pursuing an outcome.
5. Capsule polish, gradients and accents do not solve the structural density problem.

## C23 expected UI/UX

- Remove the persistent global main-action rail and persistent subaction rail from destination screens.
- Keep one compact, floating native Mool Home launcher with no full-width bottom surface.
- Use the existing `/app/mool` Home destination as the action hub; do not add a route, screen family, backend owner, persistent business state or filler action.
- Present Social, Buy, Eat, Ride, Book and Work as six clearly separated family rows with one strong main-action control and their truthful existing subactions grouped beside/below it.
- Make every target at least 44 logical pixels, with one shared icon/text/spacing/shape system and restrained family accent inside a neutral professional surface.
- Keep large block colours, full-width straps, horizontal action scrolling and decorative filler out of the hub.
- A main action or subaction is one tap from Mool Home and at most two taps from any destination: Mool Home, then the required outcome. No intermediate family-expansion tap.
- Put Chat in the Home header/action area rather than restoring a second persistent bottom control.
- Preserve Android/app Back, content reachability, truthful routes, finite motion and immediate reduced-motion behavior.

## Ticket decision

C22H device-matrix execution stops at founder rejection. C23A–C23H replace the
rejected dual-rail architecture sequentially, with host and OPPO qualification
required before another candidate can be reviewed. This document does not
authorize a build or install.
