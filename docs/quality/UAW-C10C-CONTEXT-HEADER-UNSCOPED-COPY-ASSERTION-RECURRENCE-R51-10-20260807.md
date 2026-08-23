# UAW C10C context-header copy assertion recurrence in R51.10

- Registry: `REG-20260807-202-CONTEXT-HEADER-UNSCOPED-COPY-ASSERTION-THIRD-FILE-RECURRENCE`
- Prior rule: `REG-20260807-187-CONTEXT-HEADER-TESTS-USED-UNSCOPED-COPY-ABSENCE-ASSERTIONS`
- State: resolved; complete contextual-header family gate active
- Trigger: the broad C10C affected batch failed because R51.10 expected `Flexible packs` to be absent from the entire Wholesale page.
- Root cause: the REG-187 repair covered R51.11 and R51.13 but did not inventory the full contextual-header test family.
- Durable rule: header-only copy assertions always query descendants of `buy-contextual-glass-header`; a repair must search all sibling tests for the same pattern.
- Proof: R51.10 passed 3/3 alone and the broader affected navigation batch passed 80/80.
