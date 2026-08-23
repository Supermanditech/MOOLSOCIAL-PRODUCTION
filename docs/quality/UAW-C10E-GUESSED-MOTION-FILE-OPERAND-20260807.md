# UAW C10E guessed motion file operand

- Registry: `REG-20260807-215-C10E-COMPOUND-MOTION-READ-USED-NONEXISTENT-FILE-OPERAND`
- State: resolved; the partial compound output was rejected
- Detection: `Get-Content` failed because `apps/mobile/lib/core/design/mool_motion.dart` does not exist.
- Root cause: a likely motion filename was composed from memory instead of being selected from the immediately verified design-file inventory.
- Durable prevention: inventory the exact design root with `rg --files`, filter to existing literal paths, and read only those paths; any missing operand invalidates every partial result from that compound command.
- Preservation: this was read-only and caused no runtime, build, device or evidence mutation beyond this permanent registration.
