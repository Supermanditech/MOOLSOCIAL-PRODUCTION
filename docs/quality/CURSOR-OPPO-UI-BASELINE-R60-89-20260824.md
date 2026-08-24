# Cursor OPPO UI baseline — r60.89 — 24 August 2026

Status: **mandatory incremental baseline for subsequent Cursor UI/UX tickets**

## Founder baseline declaration

The founder designated the consolidated release APK below as the latest APK for
OPPO UI testing. All subsequent Cursor UI findings and tickets must begin from
the visible and interactive runtime state of this version. Older screenshots,
APK builds and approved prototypes remain historical traceability only; they
must not replace r60.89 as the working comparison baseline unless the founder
explicitly changes the baseline.

- Version label: `moolsocial-social-auth-r60.89-20260824`
- APK filename: `moolsocial-social-auth-r60.89-20260824.apk`
- Founder-provided SHA-256:
  `1925CE2571035C0DB865E1BF45D263015BF7DFBD6940A1F74F913B19F6BC2469`
- Reported release output size: `99.6 MB`
- Reported Android build result: `assembleRelease` succeeded in `236.7s`
- Reported build date: `24 August 2026`

These facts were supplied in the founder's PowerShell build transcript. Cursor
did not read the external Desktop worktree, build script, keystore, Meta inputs
or output folder and did not independently recompute the artifact hash.

## Included Cursor UI lineage

The founder identifies r60.89 as the latest consolidated APK following the two
completed Cursor Buy UI tickets. Their recoverable source lineage is:

1. `a2cfbcc94f76d1e9b1088ce3cb6750fe9c81a917` — remove the animated Buy
   header from Shop, Wholesale and Orders;
2. `0f64f52a55e4018e9576ffce9755418c75a74ea5` — restore top-right full-page
   Account access;
3. `f373b9ad9ad2b2ee1baac5f8e4741185177e934d` — add the post-order and
   in-app invoice journey.

The build transcript does not expose the consolidated source HEAD. Future
integration and release work must still verify source provenance rather than
inferring it from the APK filename alone.

## Mandatory next-ticket gate

- Founder OPPO testing supplies the next visible issue and the exact runtime
  screenshot or interaction observation from r60.89.
- Each new ticket authorizes only its stated incremental delta from r60.89.
- Preserve the r60.89 Shop, Wholesale, Orders, Account, post-order and invoice
  behaviors unless a later founder ticket changes one explicitly.
- Before implementation, bind the observation to destination, page state,
  interaction sequence, viewport and screenshot when available.
- After implementation, run focused accessibility, navigation, state-return,
  customer-copy and regression tests and create a separate recoverable commit.
- Do not install an isolated Cursor APK over the consolidated OPPO package.
  Device review uses one newly consolidated APK after authorized integration.

## OPPO review status

OPPO installation and runtime observations for r60.89 are pending the founder's
manual UI review. Future tickets must record those observations without
assuming that a successful APK build proves installation or visible UI
conformance.

## Non-blocking build transcript observations

The supplied transcript reported 49 packages with newer incompatible versions
and a future Flutter warning for plugins that still apply the Kotlin Gradle
Plugin. The release APK nevertheless built successfully. These are not
authorized Cursor UI changes and must remain with their proper dependency and
platform owners.

No passwords, client tokens, keystore values or identifiers from interactive
secret prompts are stored in this baseline record.
