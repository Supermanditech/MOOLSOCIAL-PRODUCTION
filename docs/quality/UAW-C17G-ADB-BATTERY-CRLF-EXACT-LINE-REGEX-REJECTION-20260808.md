# C17G adb battery CRLF exact-line regex rejection

The first C17G preinstall command falsely reported that battery was not 100% because it matched the `adb dumpsys battery` text with a CRLF-sensitive end-of-line expression after `Out-String`. An immediate independent read proved `level: 100`, USB powered true, charging/full status and healthy battery.

No install occurred. The corrected preinstall gate extracts the numeric value with a whitespace-tolerant capture and validates the integer without depending on host line endings.
