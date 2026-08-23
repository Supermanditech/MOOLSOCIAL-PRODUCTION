# C16 unsupported dumpsys-window insets subcommand

## Incident

A read-only probe invoked `dumpsys window insets` on the OPPO. This ColorOS
window service does not support that subcommand and returned its help hint. The
output was discarded and no mutation occurred.

## Root cause and prevention

An Android service subcommand was assumed portable across vendor builds. C16
now reads `dumpsys window -h` first and selects only a supported read-only
window-state command. Unsupported output is never treated as IME evidence.
