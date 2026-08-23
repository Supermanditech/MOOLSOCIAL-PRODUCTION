# C30L PowerShell HOME-variable repurpose rejection

- Scope: bounded OPPO Watch replay.
- Result before rejection: the semantic `Open Home, YouTube` tap succeeded and `12-home-return.xml` was captured.
- Rejection: `$home` collided with PowerShell's read-only `$HOME` variable, so no Watch tap occurred.
- Prevention: use task-specific variables such as `$homeUiDocument` and resume from the captured Home state without repeating the prior interaction.
