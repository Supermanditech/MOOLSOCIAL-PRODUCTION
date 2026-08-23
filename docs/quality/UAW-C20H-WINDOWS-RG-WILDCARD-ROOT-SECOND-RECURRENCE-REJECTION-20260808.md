# C20H Windows rg wildcard-root second recurrence rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPPO-QUALIFICATION-FIX3-C20H`

The final C20H state lookup incorrectly supplied `config/*.json` as a Windows
ripgrep root and exited with code `2`. This repeats the registered wildcard-root
mistake. No lookup result was accepted. The correction uses literal root
`config` with `--glob '*.json'`.
