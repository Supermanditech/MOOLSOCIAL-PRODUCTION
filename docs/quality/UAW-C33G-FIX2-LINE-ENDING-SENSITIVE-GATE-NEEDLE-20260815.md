# UAW C33G FIX2 line-ending-sensitive gate needle

Pre-execution review found that the new shared Google/YouTube relationship assertion relied on exact newline strings. Those strings could reject valid source after CRLF/LF materialization.

The assertion now uses one single-quoted, whitespace-tolerant regular expression and remains subject to both supported PowerShell hosts before qualification.
