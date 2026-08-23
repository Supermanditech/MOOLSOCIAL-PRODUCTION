# REG3174 - FIX8 first prebuild manifest stale after gate hardening

## Classification

Registered rejected prebuild seal with zero build, artifact or install action.

## Evidence

The first r60.81 manifest sealed 627 owners before the complete invoked
prebuild-control graph was finalized. REG3175 corrects the initial claim that
the FIX5 gate was already listed: it was omitted, making the seal incomplete.
The rejected seal and its evidence remain preserved in the `...20260822-01`
directory. The APK gate still points to rejected r60.80, so no build could
consume it.

## Prevention

Finalize, include and pass every invoked build-control source before generating
the candidate manifest. Create a distinct `...20260822-02` seal; never
overwrite or reuse the incomplete first seal, and bind only the final
live-owner checksum into the APK gate.
