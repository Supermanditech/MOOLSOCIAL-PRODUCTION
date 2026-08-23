# UAW-C33F later release phase contracts missing

Date: 2026-08-15

## Audit finding

The C33F gate declares `preupload`, `postupload`, `preinstall` and `postinstall` as valid phases but currently has no dedicated positive state/count/evidence assertions for those phases. They fall through the same prerelease machine-state and zero-action assertions used before the AAB. This would either reject the truthful lifecycle after upload or fail to prove the exact Internal Testing activation and in-place Play update evidence promised by the parent ticket.

No upload, activation, install or device action has been attempted. The exact r60.49 AAB remains unuploaded.

## Prevention

Before any Play action, implement an explicit phase switch which preserves the one-build artifact binding, requires Internal Testing only, proves one upload/activation before install authority, requires one in-place Play update with Play installer and retained-data evidence, and rejects any other track, ADB/sideload, uninstall, data clear or downgrade. Add isolated positive and negative fixtures for every phase on PowerShell 7 and Windows PowerShell 5.1.
