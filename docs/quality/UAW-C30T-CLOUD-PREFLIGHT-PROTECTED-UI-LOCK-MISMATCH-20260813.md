# C30T Cloud preflight protected UI lock mismatch

Date: 2026-08-13

The founder-authorized Dev deployment preflight failed closed before any external write. The immutable login-account-handoff lock expected SHA-256 `B07468F487A5C04286F0D228CDCCF7EAD373154C756600C58DC216A4EDD2BD11` for `apps/mobile/test/ui_v2_customer_copy_machine_gate_test.dart`, while the current dirty-tree file is `8BB8D600D9072C69543D38B8FC20868DA7F352CFB554D5891E624BF997351CF9`.

No approved manifest will be weakened and no user-owned change will be reverted. The exact diff and ownership must be classified before any deployment retry; the approved UI lock must pass through an authorized non-presentational correction or a separately founder-approved immutable-checkpoint workflow.
