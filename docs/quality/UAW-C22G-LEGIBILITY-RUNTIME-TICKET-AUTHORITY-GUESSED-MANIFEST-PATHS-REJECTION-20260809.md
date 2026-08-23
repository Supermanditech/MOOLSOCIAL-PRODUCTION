# C22G legibility runtime-ticket authority guessed-path rejection

- Observed: 2026-08-09 before selecting any runtime repair ticket.
- Rejection: a combined authority read guessed shortened C22F and parent C22
  manifest filenames and a generic `config/mvp-ticket-queue.json`. All three
  paths do not exist. PowerShell continued and printed the valid C22G/scope
  owners, but the overall authority inventory was incomplete.
- Root cause: supporting owners were inferred from ticket labels instead of
  discovered from the verified config inventory.
- Permanent prevention: run bounded `rg --files config` discovery first, then
  read only exact literal owners. A combined lookup containing any missing
  owner is rejected as a whole and authorizes no runtime change.
- Runtime/device effect: none. No production token, build, APK or device state
  changed.
