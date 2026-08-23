# C20H r60.19 OPPO qualification preselection

State: `selected_prebuild_pending_build_install_closed`
Date: 2026-08-08

## Outcome and scope

C20H is MVP-required device qualification for the C20 visual recovery. It adds
no screen, route, feature, subaction, backend or business-state owner. It
reuses the native Flutter owners, C20G fingerprint, existing one-build wrapper,
APK machine gate and in-place OPPO install workflow.

## Reconciled inputs

- branch: `remediation/prototype-conformance-2026-07-20`;
- HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`;
- C20G cycles: 2/2, fingerprint
  `D1788BFF131954E9DB0F5B5E33A693060E6B1F4A79EC111406F20C8491CB6202`;
- path-safe Git inventory before selection: 2,325 entries, 137 tracked
  changes, 2,188 untracked owners, zero staged changes, SHA-256
  `59CC6AC45A8A28CFA7D1D0887A28063D3C5C8C4E1C9C37A0EA7E5FDDDF0CC663`;
- connected unlocked device: OPPO CPH2375, serial `2b3e0f71`, 100% battery,
  approximately 84.6 GB free on `/data`;
- live installed package: `com.moolsocial.app`, `1.0.0-r60.18`
  (`2026080818`), first install `2026-08-04 02:51:59`, last update
  `2026-08-08 17:57:54`;
- successor reservation: `1.0.0-r60.19` (`2026080819`), with no version or
  artifact-directory collision.

The live predecessor checksum must still be re-proved by pulling the installed
base during final prebuild. Build and install remain closed at selection.

## Minimum complete scope and stop boundary

Seal the current source/dirty/device inputs; pass scope, memory, protected UI,
brand, copy, interaction and APK prebuild gates; prove the authorization gate
rejects while closed; open exactly one build authorization; run the wrapper
once; validate package, version, signer, checksum and postbuild source identity;
open one install authorization; install once in place; prove installed identity;
and capture the cumulative six-family/seventeen-state real-device matrix.

Any source drift, protected-gate failure, package/version/signer/checksum
mismatch, device lock/disconnect, install failure or need for a second build or
install ends mutation. The r60.18 evidence remains immutable.
