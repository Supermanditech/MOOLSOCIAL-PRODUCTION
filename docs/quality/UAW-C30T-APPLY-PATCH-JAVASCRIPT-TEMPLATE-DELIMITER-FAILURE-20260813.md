# C30T apply-patch JavaScript template delimiter failure — 2026-08-13

## Outcome

The first attempt to create three regression evidence documents did not reach
the patch tool because unescaped Markdown delimiters made the JavaScript wrapper
syntactically invalid. The failed wrapper returned before any patch or file
mutation occurred.

## Root cause and prevention

Patch content containing language delimiters was embedded in a JavaScript
template literal without a mechanical escape review. Each evidence file was
then added through an independent ordinary quoted string, one patch per file.
Future patch wrappers avoid delimiter-bearing template literals and retain
file-local, independently complete patches.

Because the regression registry and this evidence are source-sealed, both
no-AAB qualification cycles must be repeated before build authority can be
activated.
