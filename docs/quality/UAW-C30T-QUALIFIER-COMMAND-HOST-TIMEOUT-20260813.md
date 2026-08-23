# C30T qualifier command-host timeout

Date: 2026-08-13

The first launch of C30T qualification cycle 1 was terminated by the short-lived command host before the qualifier produced output. The retained console log is zero bytes and a read-only process audit confirmed that no qualifier process remained active. No AAB was built, no app was installed, no OPPO data was changed and no external deployment occurred.

Root cause: a long-running qualifier was invoked through a command host with an effective timeout of only a few seconds.

Permanent prevention: launch each long-running qualification cycle as a hidden durable PowerShell process, record its PID and an explicit exit-code marker, and poll those records without launching a duplicate process. The empty first log remains retained as evidence.
