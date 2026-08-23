# r60.18 founder gallery visual rejection and C20 successor tickets

Date: 2026-08-08

Device: OPPO CPH2375 (`2b3e0f71`)

Installed candidate: `1.0.0-r60.18` (`2026080818`), installed base SHA-256 `88F82D203E1C8C565BE5DEBB61E6C1EF1F9E588017EADB9120D97B4B3081ED2C`

## Evidence and disposition

The founder saved six full-screen screenshots and six crops in OPPO Photos covering Social / Shorts, Buy / Shop, Eat / Order Food, Ride / Bike, Book / Doctor and Work / Earn Today. All twelve originals were pulled without changing the device files and inspected at original resolution. The source-path, timestamp, byte-size, dimensions and SHA-256 manifest is under `artifacts/quality/uaw-personal-mvp-r60-18-oppo-install-transport-recovery-fix1-c17h-20260808-01/founder-gallery-audit/manifest.tsv`.

r60.18 remains installed and checksum matched, but founder device acceptance is rejected for the subaction presentation. Build and install authorization are closed. The accepted C15, C16, C17 and r60.18 evidence remains preserved.

## Screenshot-by-screenshot audit

| Evidence | State | Observed issue |
| --- | --- | --- |
| 18:07:44 full + 18:07:56 crop | Social / Shorts | Four controls read as a second opaque gray navigation bar over media. YouTube provider marks are optically smaller than the Feed/Create icons. Lavender selection styling conflicts with the permanent navy main-action selection. |
| 18:08:03 full + 18:08:10 crop | Buy / Shop | The orange page wash and burnt-orange selected glass combine into a large orange block at the bottom. Wholesale and Medicine are crowded inside the narrow four-action cells. The left chevron overlaps the main-action viewport and appears actionable although it is not. |
| 18:08:17 full + 18:08:22 crop | Eat / Order Food | Green selection establishes another visual language unrelated to Social, Buy or the navy selected main action. The two wide controls look like a separate segmented switch rather than compact members of the selected Eat family. |
| 18:08:29 full + 18:08:35 crop | Ride / Bike | Blue selection adds a fourth selection language. The left overflow cue/fade visibly covers the neighbouring Eat action, while the always-expanded local row and persistent main row compress reachable content. |
| 18:08:42 full + 18:08:47 crop | Book / Doctor | Purple selection adds a fifth visual language. The selected subaction, selected navy Book main action and left ghost chevron compete for primary attention. |
| 18:08:54 full + 18:08:59 crop | Work / Earn Today | Ochre selection adds a sixth visual language. The selected glass is visually beige rather than transparent and brand-led; the side cue again obscures the left neighbour. |

## Cross-family defects

1. **No truthful hide/show interaction.** The subaction row is permanently expanded. The chevron visible beside Buy, Eat, Ride, Book and Work is the global main-rail overflow cue. It is rendered inside `IgnorePointer`, has a 22 logical-pixel visual width and cannot be tapped. Its direction depends on scroll position, so it resembles a disappearing/reappearing subaction toggle while providing neither behavior nor semantics.
2. **Two stacked navigation bars dominate the content.** A fixed 52 logical-pixel local rail sits above the 48 logical-pixel global rail on every destination. On the real device this presents as roughly two full bottom navigation rows. It consumes content height and makes local destinations feel like another app-level navigation layer.
3. **Six unrelated accent grammars fragment the brand.** Social lavender, Buy burnt orange, Eat green, Ride blue, Book purple and Work ochre all compete with the single navy selected main-action state. Family ownership should come from position, icon, label, selected-main anchoring and restrained connection—not six arbitrary selected-control color systems.
4. **The glass result depends too strongly on the page beneath it.** The same alpha and blur look gray/opaque over Social media, orange and blocking over Buy, pale gray over Eat/Ride/Book and beige over Work. Passing source-token alpha checks did not guarantee professional composited pixels on OPPO.
5. **Selected state is over-specified.** Tinted fill, colored border, colored icon, shadow/glow and underline all fire together above an already selected navy main action. This creates two competing primary selections instead of a main family with subordinate choices.
6. **Raw token equality does not produce optical equality.** The shared owner uses 76/88/104 logical-pixel preferred widths for four/three/two actions, a 20-pixel icon box, 12-pixel label, 2-pixel icon-label gap and 14-pixel radius. Long four-action labels are tight, two-action controls become visually dominant, provider SVGs appear smaller than Material icons, and selected weight changes from 700 to 800.
7. **The current connection is not legible enough to establish hierarchy.** The thin low-opacity wave is frequently lost against the page or glass while the family tint is visually stronger. Customers see two independent rails rather than subactions belonging to the selected main action.
8. **Global overflow and local disclosure meanings are conflated.** A side chevron cannot simultaneously mean “more main actions” and be expected to hide/show the row above. The two controls need separate placement, semantics and minimum hit targets.

## Approved professional direction

- Subactions are expanded by default so routine selection remains one tap.
- Tapping the already selected main action toggles only its own subaction row. The whole selected main-action target remains at least 48 logical pixels and gains a visible up/down disclosure badge plus exact “Hide/Show [family] options” semantics. It must not navigate, reset content or add history.
- A collapsed row reaches zero layout height; the selected main action and its disclosure badge remain visible, so recovery never depends on a hidden gesture. Each family starts expanded on a fresh app process and may remember its founder/customer-selected disclosure state only for the current in-memory session.
- Expanded/collapsed motion is finite (target 160–200 ms) and settles immediately under reduced motion. System Back retains navigation meaning and is not hijacked to reveal the row.
- The global main-rail overflow cue is separately truthful: any arrow glyph must be an actual non-overlapping target of at least 44 logical pixels with Previous/Next main-actions semantics. If it stays non-interactive, it must be an edge fade without an arrow glyph.
- One neutral glass grammar is used across all six families. The rail itself remains transparent; there is no full-width color band, trapezoid or panel. Individual controls retain background visibility and meet 4.5:1 composited text contrast on the audited light and media surfaces.
- Selection uses the existing Mool identity palette: identity navy on light surfaces and identity white with at most one restrained saffron or green micro-indicator on media. Custom family-selected fills are removed. Family ownership remains explicit through icon, label, selected-main alignment and connector geometry.
- Every control keeps a 48 logical-pixel height and common radius. Count-specific widths may adapt for two, three and four actions but remain compact, centered and bounded; four-action long labels receive enough width at 360 logical pixels and a tested 320-pixel fallback without clipping.
- Labels target a shared 13 logical-pixel, 700-weight, single-line navigation style with a proven line height and maximum 130% navigation text scale. Selection must not rely on an abrupt weight jump alone. Icons use one optical box and per-asset optical normalization.
- No filler action, route, screen, backend owner, business-state owner or extra routine tap is added. Global rail geometry, order, position and meaning remain preserved.

## Ordered successor tickets

1. `C20A` — founder gallery evidence, exact visual rejection and professional contract (complete; no runtime mutation).
2. `C20B` — shared, discoverable active-main disclosure behavior plus truthful non-overlapping global overflow controls.
3. `C20C` — one neutral brand-glass control/token owner for shape, typography, icon optical sizing, spacing, selected/pressed/disabled and light/media contrast.
4. `C20D` — Social and Buy four-action conformance on media and commerce backgrounds.
5. `C20E` — Eat, Ride, Book and Work two/three-action adaptive conformance without filler or unnatural spread.
6. `C20F` — machine-readable 17-state, 2/3/4-count, contrast, occlusion, disclosure, motion, reduced-motion, semantics and reachability gates.
7. `C20G` — two consecutive unchanged-source qualifying host cycles and the complete required suite.
8. `C20H` — only after C20G, one separately authorized unique successor APK, one in-place OPPO install, checksum identity and cumulative six-family/relevant-state matrix; founder acceptance remains pending.

The parent manifest is `config/uaw-personal-mvp-global-subaction-founder-gallery-professional-recovery-fix3-c20-ticket.json`. Runtime implementation, APK build and device install are not authorized by C20A.
