# REG-20260820-3037 Cursor B2 tracked owner matched broad secret exclusion

## Incident

Cursor resumed B2 in the preserved B1 worktree after generation 3007. Before
copying source, the manifest preflight found a tracked repository owner whose
path matched one of the cutover's broad secret-exclusion patterns. It failed
closed without emitting the path or value.

## Impact

- No source file was copied.
- No reconstruction manifest, staging, commit or tag was created.
- B1 remains preserved and clean apart from the authorized generation-3007
  cutover-state copy.
- The frozen original checkout was untouched by Cursor.

## Root cause

The cutover exclusion policy intentionally used broad path classes such as
credential/private-key/service-account terms. A tracked sanitized code,
configuration or evidence owner can share one of those lexical terms without
containing a secret, so path matching alone is not a sufficient classification.

## Prevention

Do not retry or weaken the broad exclusion. Primary must classify the exact
tracked match privately from Git metadata, never read secret contents, and
either add one literal sanitized-owner allowlist entry with its current hash or
retain the permanent exclusion. Cursor then refreshes the copied cutover-state
generation and retries B2 from the existing worktree only.

## Private classification result

The sole tracked match is the intentional sanitized template
`backend/functions/.env.example`, bytes `889`, SHA-256
`17AC0C7579555A4F8A28570A26FA35B80979D572A57C9EA1E311B7B18B524F15`.
Private-key, client-secret, access/refresh-token and Google-services markers are
all absent. B2 may allowlist only this exact path at this exact digest; every
other `.env*` owner remains excluded.
