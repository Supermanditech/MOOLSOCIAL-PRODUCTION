# REG-20260817-2740: C34L evidence-audit interpolated path colon parser

## Truthful event

During a read-only producer-owner inventory, the evidence sub-agent composed a
double-quoted PowerShell error string with a colon immediately after
`$rootPath`. PowerShell parsed the colon as part of the variable reference and
rejected the command before any search executed. The agent stopped without
retry or mutation.

No assigned owner, candidate state, source seal, cycle, AAB, device, Google
Play, credential, secret, deployment, or external state changed.

## Root cause

The diagnostic interpolated a variable followed by punctuation without an
explicit variable-name boundary, repeating the permanent PowerShell
colon-after-variable prevention.

## Prevention

- Use `${rootPath}:` when punctuation must follow an interpolated variable.
- Prefer format strings or separate scalar fields for diagnostic messages.
- Parser-check the bounded inventory command before using it for required
  producer discovery.

## Candidate consequence

C34L remains selection-only at zero release actions. The failed command
performed no producer search and invalidates no candidate evidence.
