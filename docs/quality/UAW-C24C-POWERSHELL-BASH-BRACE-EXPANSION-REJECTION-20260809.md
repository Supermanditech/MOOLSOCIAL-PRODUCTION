# C24C PowerShell Bash brace-expansion rejection — 2026-08-09

The first read-only ownership search used `{eat,ride,book,work}` in a
PowerShell command. PowerShell parsed the commas as invalid argument syntax and
ripgrep never ran. REG650 requires explicit quoted path arguments.
