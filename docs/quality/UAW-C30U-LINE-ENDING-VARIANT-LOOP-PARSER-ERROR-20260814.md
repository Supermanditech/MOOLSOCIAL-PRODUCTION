# C30U line-ending variant loop parser error

A compressed nested-loop diagnostic omitted a closing brace while comparing
platform-test byte variants. PowerShell rejected it before any result.

The retry uses explicit fixed variants. No source or release mutation occurred.
