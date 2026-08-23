# UAW C30T inherited approved-UI-lock preflight rejection — 2026-08-13

The post-implementation lock check reproduced the previously registered C29R
and C30C mismatch in the shared customer-copy test:

- owner: `apps/mobile/test/ui_v2_customer_copy_machine_gate_test.dart`
- immutable lock SHA-256: `B07468F487A5C04286F0D228CDCCF7EAD373154C756600C58DC216A4EDD2BD11`
- preserved observed SHA-256: `8BB8D600D9072C69543D38B8FC20868DA7F352CFB554D5891E624BF997351CF9`
- preserved diff: 126 insertions, 1 deletion

This is the exact Social customer-copy expansion documented on 2026-08-11,
not a C30T delta. C30T does not edit the shared test, the Screens 01–03 files,
or the immutable lock. Separate founder reference authority is still required
to reconcile the shared owner. Remaining C30T gates run independently and do
not convert this known rejection into a pass.
