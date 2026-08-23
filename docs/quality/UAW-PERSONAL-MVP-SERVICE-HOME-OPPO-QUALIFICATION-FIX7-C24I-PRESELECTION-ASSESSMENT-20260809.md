# C24I service-home OPPO qualification preselection — 2026-08-09

## Customer outcome and classification

C24I is `mvp_required` device acceptance work. One unique checksum-proven C24
successor may be built only after a fresh prebuild/machine/device audit, then
installed in place on OPPO and left pending founder visual acceptance.

## Host qualification and predecessor

C24H passed two complete unchanged-source cycles on fingerprint
`C36B48111C25B6C84F059D49D1B961BFA4F2742348C747DDA02D16316D00876C`.
The protected predecessor is installed r60.22 / `2026080922`, checksum
`778C9338DAFDEC3693337D54410946C75F9B6B1BB5977D822DF2CF7E38D9D850`,
first install `2026-08-04 02:51:59`. It was device-rejected only because its
outer semantic buttons were not Android-clickable; C24B1–C24B3 and the C24H
suite now cover real tap actions.

## Reuse and smallest complete scope

Reuse the existing single-build wrapper, APK machine gate, in-place ADB
upgrade and OPPO evidence workflow. Create no screen, route, backend,
persistent state, family or subaction. The bounded sequence is:

1. reconcile branch/HEAD/full dirty tree and connected OPPO state;
2. prove negative build authorization while build/install remain closed;
3. seal the qualified source and r60.22 predecessor;
4. open exactly one candidate build authorization;
5. perform exactly one profile wrapper build and postbuild validation;
6. separately authorize one `adb install -r` after device/install gates pass;
7. prove local/live/pulled checksum, version, signer and preserved first install;
8. prove Android `clickable=true`, Home, all families/service homes, Back,
   MoolSocial and Chat continuity, then leave founder acceptance pending.

## Explicit exclusions

No second build/install, uninstall, data clear, downgrade, runtime or
screenbook mutation, credentials, messages/calls, funds, Production, commit,
push, deploy or promotion. Preselection itself opens no build or install
authority.
