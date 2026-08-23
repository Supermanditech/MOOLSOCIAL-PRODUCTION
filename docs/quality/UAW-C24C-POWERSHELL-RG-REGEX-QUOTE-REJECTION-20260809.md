# C24C PowerShell ripgrep regex quote rejection — 2026-08-09

A test-name search placed a literal double-quote regex branch inside a
PowerShell double-quoted string. PowerShell terminated the string and raised a
parser error before ripgrep could inspect any file.

REG653 requires single-quoted PowerShell regex arguments, or separate simpler
searches, whenever the pattern includes literal double quotes.
