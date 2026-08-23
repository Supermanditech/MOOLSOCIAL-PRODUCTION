# C28E preselection — Android exported-semantics host remediation

Classification: `mvp_required`.

## Customer outcome

A Personal customer can reach Mool and every visible family/local destination
through an Android-exported accessibility target of at least 44 by 44 logical
pixels while the accepted 58-pixel rail, direct routes and one-handed placement
remain intact.

## Reuse and duplicate assessment

- Reuse the one shared `MoolDestinationNavigationV2` rail and the existing
  startup system-UI owner. No feature-local rail, screen, route, state owner or
  backend is created.
- Replace C28B's unsupported manual system-UI request with explicit mandatory
  edge-to-edge ownership. Flutter 3.44 targets Android API 36, where non-edge
  modes cannot be restored.
- Add only the Android clearance required by the exported window calculation:
  the top system inset minus the 14 logical pixels by which a 58-pixel rail may
  exceed the 44-pixel minimum. The cell itself remains 58 pixels high.
- Reuse the C28C two-cycle host-qualification topology and migrate its installed
  predecessor identity to checksum-preserved r60.27.
- Migrate the device-bounds expectation to the completed FSC01/FSC06 catalogue:
  Social has no duplicate family root and Buy has no duplicate Products cell.

Official Flutter system-UI documentation:
`https://api.flutter.dev/flutter/services/SystemChrome/setEnabledSystemUIMode.html`.
Official Android inset guidance:
`https://developer.android.com/develop/ui/views/layout/edge-to-edge`.

## Smallest complete implementation

1. Make the shared Android system-UI request truthfully edge-to-edge.
2. Derive one shared Android exported-semantics clearance from live insets.
3. Prove 58-pixel Flutter cells and a simulated exported minimum of 44 pixels
   at the OPPO 360 by 806 logical viewport.
4. Run focused tests and two complete consecutive host cycles with one stable
   source fingerprint.

## Explicit exclusions

No visual token, icon, label, route, navigation meaning, content, backend,
provider, credential, accepted Screen 01–03 owner, APK build, device install,
uninstall, data clear, downgrade, Production write, commit, push or promotion.
C28D r60.27 and its evidence remain immutable throughout C28E.

## Dependencies and test plan

- Founder implementation and later OPPO-test direction received 2026-08-10.
- C28D's 54 by 19 logical rejection and installed r60.27 identity preserved.
- FSC01 and FSC06 navigation corrections preserved.
- Focused system-mode, layout, text-scale, keyboard and reduced-motion tests.
- Static C28E owner gate, complete analyzer, approved locks, protected Social
  and Buy seals, interaction/copy/brand gates and two identical host cycles.

Estimated impact: one day. No route/screen/backend count changes; the work
remains within the founder-locked 60–75 day robust-MVP window.
