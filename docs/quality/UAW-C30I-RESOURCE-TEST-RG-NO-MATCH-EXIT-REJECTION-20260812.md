# REG-20260812-1388 — C30I resource-test rg no-match exit rejection

- Phase: C30I reuse/duplicate audit
- Failure: The bounded search for existing `styles.xml` or `defaultFocusHighlightEnabled` tests found no matches, but the command did not explicitly normalize `rg` exit code 1 as a valid no-owner outcome.
- Permanent prevention: For duplicate-audit searches where zero matches is an accepted result, capture the output and explicitly classify exit code 0 as matches, 1 as no matches, and any other code as failure.
- Protected state: Read-only failure only; no source, device, build, install or deployment mutation occurred.
