# UAW C10E regression entry referenced a future gate

- Registry: `REG-20260807-218-C10E-REGRESSION-ENTRY-REFERENCED-NOT-YET-CREATED-STATIC-GATE`
- State: resolved before retry
- Detection: regression memory rejected REG217 because its gate list named the planned C10E checker before that file existed.
- Root cause: the prevention design was recorded as though its future implementation were already repository evidence.
- Durable prevention: new entries initially reference only existing files. A newly implemented checker may be attached only after it exists, parses and passes independently.
