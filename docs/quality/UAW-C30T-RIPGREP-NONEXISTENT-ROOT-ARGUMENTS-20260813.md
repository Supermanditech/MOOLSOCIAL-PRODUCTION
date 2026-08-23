# C30T ripgrep nonexistent-root arguments

- Date: 2026-08-13
- Repository: `C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION`
- Scope: read-only backend source audit

A bounded ripgrep command searched existing `apps` and `packages` roots but also guessed `functions` and `services`, which are absent. ripgrep returned useful mobile credential-path matches and then reported path errors for the two missing roots.

No file or external state changed. The backend audit must first enumerate repository-owned paths with `rg --files`, verify candidate roots exist, and search only those exact paths.
