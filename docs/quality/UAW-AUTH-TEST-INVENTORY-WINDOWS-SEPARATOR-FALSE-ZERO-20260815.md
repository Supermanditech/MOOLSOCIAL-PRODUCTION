# Auth test inventory Windows separator false zero

- Regression: `REG-20260815-2466-AUTH-TEST-INVENTORY-WINDOWS-SEPARATOR-FALSE-ZERO`
- Failure: a forward-slash-only filter over `rg --files` output found zero auth test paths on Windows.
- Impact: no test ran and no file changed; the zero result is not accepted as an inventory.
- Prevention: filter by exact test basenames or a separator-neutral expression and require one or more verified current paths before execution.
