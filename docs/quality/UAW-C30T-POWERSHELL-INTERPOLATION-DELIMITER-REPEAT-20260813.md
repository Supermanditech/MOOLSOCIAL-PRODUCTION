# UAW C30T PowerShell interpolation delimiter repeat — 2026-08-13

The corrected relative-path classifier then repeated REG-1813 by placing
`$marker:` inside a double-quoted wildcard. PowerShell rejected it before the
classification ran. The result is discarded. The correction uses the format
operator (`'*{0}:*' -f $marker`) and the repeat remains permanently recorded.
