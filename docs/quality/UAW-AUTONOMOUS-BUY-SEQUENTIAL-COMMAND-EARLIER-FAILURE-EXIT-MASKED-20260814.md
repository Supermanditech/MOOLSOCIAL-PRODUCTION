# Autonomous Buy sequential command earlier-failure exit masking

Date: 2026-08-14
Registry ID: `REG-20260814-2114-AUTONOMOUS-BUY-SEQUENTIAL-COMMAND-EARLIER-FAILURE-EXIT-MASKED`

A failed repository gate was followed by a successful package typecheck in the same shell command. The overall result used the final command's zero exit, which could have produced a false pass if the printed gate error were ignored.

The combined result is rejected. Each qualification boundary is rerun in its own tool call so its exit code cannot be masked. No product or backend source was changed.
