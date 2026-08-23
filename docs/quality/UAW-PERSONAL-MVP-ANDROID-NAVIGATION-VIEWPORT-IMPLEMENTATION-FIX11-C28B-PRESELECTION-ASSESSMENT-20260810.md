# C28B preselection — Android navigation viewport implementation

Classification: `mvp_required`.

Customer outcome: Mool, family and local destination cells remain visually
unchanged but are wholly owned by the Android interactive/accessibility
viewport on supported devices.

## Smallest implementation and reuse

- Reuse every C27 Flutter navigation, route, state, copy and token owner.
- Add one shared Dart system-UI viewport owner that requests both visible system
  overlays on platforms where the OS still permits non-edge-to-edge layout;
  unsupported modes remain OS-ignored on mandatory edge-to-edge releases.
- The protected UI lock rejected `MainActivity` as an immutable Screens 01–03
  owner. It remains byte-for-byte unchanged. The shared Dart `SystemChrome`
  mode is therefore the sole lawful window-policy owner; Android itself
  restores that selected mode after keyboard/system-UI interruption.
- Retain the existing edge-to-edge Flutter/SafeArea path on Android 15 and
  later, where edge-to-edge is mandatory.
- Add one focused shared-shell widget test and one bounded static gate; do not
  add a feature-local implementation or another screen.

## Explicit exclusions

No visual redesign, rail height/width/colour/type/icon/label change, new route,
action, copy, session, controller, backend, provider action, APK build or
device install. r60.26 remains installed until later host qualification opens
one successor candidate.

## Dependencies and evidence

C28A complete; C27F rejection retained; immutable Screens 01–03 and protected Social/Buy locks; current
branch/dirty tree; permanent regression memory. Acceptance requires formatting,
analysis, focused widget/static tests, pre-Android-15 system-overlay ownership, no
Android-15 opt-out, and unchanged C27 visual geometry.

Timeline impact is one day and remains inside the 60–75-day lock.
