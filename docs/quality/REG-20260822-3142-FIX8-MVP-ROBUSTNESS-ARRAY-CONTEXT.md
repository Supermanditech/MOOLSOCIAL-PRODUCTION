# REG-20260822-3142 — FIX8 MVP robustness-array context rejection

Date: 22 August 2026

State: registered; zero robustness-array mutation

After the FIX8 current-ticket, selected manifest and shared-owner transitions
were independently accepted and read back, the robustness-coverage array patch
was rejected because its expected strings did not match the live JSON byte
context. The rejection was atomic for that patch; already accepted earlier
subtrees remain parsed and unchanged.

No source, test, build, APK, OPPO, provider, account, email/SMS, Play or cloud
state changed from the rejected array patch.

Root cause: the array replacement reused earlier rendered text instead of a
fresh exact local read after incremental state changes.

Prevention: locate the selected assessment through its exact current ticket ID,
read only the immediate named array block and patch that literal block alone.
Parse and count the new array before moving to another selected-assessment
field.
