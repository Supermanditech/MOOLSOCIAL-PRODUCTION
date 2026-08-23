# C32X R15 action-choice navigation accessibility test successor qualification

C32X migrated only the hidden `MvpActionChoiceRootV2` navigation assertions
inside R15. The final compact journey opens the standalone Mool launcher,
requires the connected navigator, closes it through the explicit unobscured
outside-dismiss owner, then verifies the independent root Back callback. The
removed selected-main, root-Mool and root-Chat compatibility controls remain
absent.

The warning-bearing intermediate run was rejected: tapping the launcher under
the modal overlay reached the outside-dismiss layer rather than the named
control. REG-2288 preserves that mistake. The final run used the explicit
outside-dismiss key and emitted zero hit-test warnings.

## Exact results

- R15: 16 passed, 0 failed, 0 warnings.
- Current FIX2 action-choice authority: 25 passed, 0 failed.
- Current R03 Mool Home authority: 11 passed, 0 failed.
- Current C24B2 compact authority: 4 passed, 1 declared capture skip, 0 failed.
- Targeted analyzer: clean.
- C32W shared-owner lifecycle gate: passed on PowerShell 7 and Windows
  PowerShell.
- C32X gate: passed on PowerShell 7 and Windows PowerShell.
- Bounded combined C32S/C32T/C32U/C32V/C32X five-file successor batch:
  36 passed, 0 failed, 0 warnings; all five files analyze clean together.
- Ordered C32R-C32X source/test manifest: 62 exact owners with real tab
  separators, zero malformed rows, zero stale hashes and zero duplicates.

Final R15 SHA256:
`F0AD3D0E6DCBE68C8C6BFEBD0AE19CF184A59DADA5118C3A165E0DA716A3DC88`.
The production action-choice owner remains unchanged at SHA256
`1D6D9664E832D3C149101E2F205376A52A48EC6C2888EE9BAFEC20D22F496C2C`.

C32W's exact intermediate 15-pass/1-hidden-failure hash remains preserved in
its machine state. C32X authorizes no runtime, backend, build, Play, OPPO,
provider, secret, email, quota or other external action.
