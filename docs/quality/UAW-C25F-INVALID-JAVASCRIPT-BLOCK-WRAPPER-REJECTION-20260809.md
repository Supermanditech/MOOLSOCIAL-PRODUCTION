# C25F invalid JavaScript block wrapper rejection

- Date: 2026-08-09
- Status: registered before search retry

An explicit negative ripgrep audit was wrapped in invalid orchestration JavaScript (`let{...}`), so the shell command never ran. The retry uses a normal block with a declared constant and preserves the required explicit ripgrep exit-code handling.
