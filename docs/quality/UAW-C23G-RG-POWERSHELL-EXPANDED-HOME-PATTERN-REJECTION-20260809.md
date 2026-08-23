# C23G ripgrep PowerShell interpolation rejection

A read-only source search placed `$home` in a PowerShell double-quoted regex.
PowerShell expanded the token to the profile path and ripgrep rejected the
resulting escape sequence. No file or device changed. REG-20260809-574 requires
literal single-quoted or fixed-string search arguments for dollar-prefixed
source tokens.
