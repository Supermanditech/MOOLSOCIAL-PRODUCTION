# UI design memory path guess regression

- Regression: `REG-20260815-2470-UI-DESIGN-MEMORY-PATH-GUESSED`
- Failure: the resumed read used a descriptive but nonexistent design-memory filename instead of the repository's literal owner path.
- Impact: the command failed read-only; no repository or external state changed.
- Prevention: resolve retained document owners through a bounded `rg --files` inventory and use only the exact returned path.
