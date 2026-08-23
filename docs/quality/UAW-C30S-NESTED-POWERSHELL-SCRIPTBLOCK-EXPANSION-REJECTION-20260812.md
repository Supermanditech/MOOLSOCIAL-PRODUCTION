# C30S nested PowerShell scriptblock expansion rejection

Date: 2026-08-12

A read-only Gradle properties diagnostic was wrapped in a second double-quoted
PowerShell command. The outer parser consumed the inner `$_` token, so the
filter rejected with `.Line` treated as a command. Gradle packaging was not
requested and no APK, AAB, device, Play, Firebase or provider state changed.

Prevention is to invoke Gradle directly from the current PowerShell host and
parse its output without a nested PowerShell command string.
