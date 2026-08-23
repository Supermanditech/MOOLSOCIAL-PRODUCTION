# UI reading inventory bare foreach pipeline regression

- Regression: `REG-20260815-2468-UI-READING-INVENTORY-BARE-FOREACH-PIPE`
- Failure: a read-only PowerShell file-size inventory piped a statement-form `foreach` directly and failed parsing.
- Impact: no file was read through that failed command and no repository or external state changed.
- Prevention: assign loop output to an explicit array first, then pipe that array for formatting.
