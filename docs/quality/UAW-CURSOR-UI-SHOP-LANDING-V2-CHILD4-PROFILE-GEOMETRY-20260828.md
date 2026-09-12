# UAW-CURSOR-UI-SHOP-LANDING-V2-CHILD4-PROFILE-GEOMETRY-20260828

State: `shared_profile_geometry_defect_authorized_for_bounded_fix`

- Parent: `UAW-CURSOR-UI-SHOP-LANDING-V2-20260828`.
- Work ID: `shop-v2-child4-profile-geometry-20260828`.
- Task: `/root/cursor_shop_v2_child4_profile_geometry_20260828`.
- Branch: `work/cursor-ui/shop-v2-child4-profile-geometry-20260828`.
- Baseline: `db3b0036246843ff44a3002a063046bac9a65574`.

## Defect

The shared `MoolGlobalProfileShortcutV2` declares a 44×44 contract but rendered
at 48×45 in the Shop header. This breaks the exact cross-destination geometry
and spacing standard requested for Shop, Workspace, Care, Travel and Social.

## Scope

- Constrain the shared shortcut itself to an exact 44×44 outer box.
- Preserve its circular shape, icon, colours, semantics, tooltip and callback.
- Replay the Shop entry plus existing shared-profile tests and destination
  consumers; do not change the global profile panel or destination layouts.

No backend, device, configuration or accepted-reference owner is changed.
