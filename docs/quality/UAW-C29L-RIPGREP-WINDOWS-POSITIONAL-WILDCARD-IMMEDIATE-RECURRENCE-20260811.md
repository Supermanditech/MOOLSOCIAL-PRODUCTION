# C29L ripgrep positional wildcard immediate recurrence

Immediately after registering REG-1205, a follow-up test inventory again passed `apps/mobile/test/social_v2*` as a positional ripgrep path. Windows rejected the unexpanded wildcard before the test inventory ran.

The recurrence occurred because the replacement discipline was not applied to every positional input in the next command. All subsequent ripgrep searches must use exact confirmed paths and `-g` filters only. No source, provider, build, device or protected runtime changed.
