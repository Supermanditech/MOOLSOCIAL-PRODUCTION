# C23H OPPO qualification preselection — 2026-08-09

## Customer outcome and classification

C23H is `mvp_required` device acceptance work. One checksum-proven successor
will be installed in place on OPPO and left pending founder visual acceptance.
C23G passed two consecutive unchanged-source cycles on fingerprint
`5C465E989187288ACDEB3BCE0C98FB2CC3214DA0398126F24D4A1A5881E78B01`.

## Reuse and duplicate search

Reuse is limited to the existing single-build wrapper, APK machine gate,
in-place ADB install workflow and OPPO evidence workflow. No screen, route,
runtime owner, backend owner, persistent business state, family or subaction is
added. Reserved r60.22 version and evidence-directory collision searches found
no prior owner.

## Predecessor and machine state

- connected OPPO CPH2375: serial `2b3e0f71`
- installed package: `com.moolsocial.app`
- installed version: `1.0.0-r60.21` / `2026080921`
- live installed base SHA-256:
  `17AF5DC2353E7195A597555C88AA42B345AFFDA0EC160900B55B0D3E822691BE`
- first install: `2026-08-04 02:51:59`
- last update: `2026-08-09 00:36:10`
- battery: 100%; `/data` free: 83,808,636 KiB
- active Flutter/Gradle build/test clients: 0
- idle Gradle daemons: 1, reported separately and left untouched
- device wakefulness at preselection audit: asleep; awake/unlocked proof must be
  reacquired before install

This exact r60.21 identity remains untouched during prebuild validation.

## Reserved candidate and smallest complete scope

The unique reserved candidate is
`UAW-PERSONAL-MVP-HOME-HUB-OPPO-QUALIFICATION-FIX6-C23H`, version
`1.0.0-r60.22` / `2026080922`, profile mode. The smallest complete scope is:

1. negative build-authorization self-test while build remains closed;
2. sealed source, branch, dirty-tree, host-cycle and predecessor validation;
3. exactly one separately opened wrapper build;
4. package/version/signer/source postbuild validation;
5. exactly one separately opened `adb install -r` in-place install;
6. local-versus-installed checksum identity and preserved first-install time;
7. cumulative six-family, relevant subaction, Back, Mool, Chat, motion and
   reachability evidence;
8. founder acceptance left pending on OPPO.

## Explicit exclusions

No second build/install, uninstall, data clear, downgrade, runtime mutation,
screenbook mutation, credentials, messages/calls, funds, Production, commit,
push, deploy or promotion. Prebuild selection opens no build or install
authority.
