# UAW-C33F preupload test postbuild fixture inherited live authority

Date: 2026-08-15

## Preserved failure

After dual-host postbuild qualification, the mutable C33F state correctly advanced `uploadAuthorization` from `held_postbuild_qualification` to `available_once`. The first `preupload` main-gate replay stopped before Play because its embedded FIX5 fixture suite cloned the current live state for the synthetic `postbuild` case and did not reset that field to the exact postbuild value.

The production `preupload` phase contract was not reached. Build/upload/install/device counts remain `1/0/0/0`, the upload authority remains available once, and no Play, OPPO or other external action occurred.

## Root cause and prevention

The fixture suite normalized prerelease and later phase values but treated the current postbuild state as a stable template. Lifecycle tests must be independent of the live state's current phase. Every synthetic phase fixture must explicitly assign all phase-owned machine-state, authority and count fields before execution. Add a bounded static assertion proving those postbuild assignments remain present, then replay both PowerShell hosts before any upload.
