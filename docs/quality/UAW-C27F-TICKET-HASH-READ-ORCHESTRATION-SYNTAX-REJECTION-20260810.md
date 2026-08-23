# C27F ticket-hash read orchestration syntax rejection

After the C27F ticket opened one-build authority, the read-only hash command
was wrapped in malformed JavaScript and did not execute. Scope build authority
and APK machine state remained closed, so no build could start.

Tool orchestration calls must use the established direct awaited-call form.
