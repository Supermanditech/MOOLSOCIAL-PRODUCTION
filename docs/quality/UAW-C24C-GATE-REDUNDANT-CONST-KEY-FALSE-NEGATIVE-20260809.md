# C24C gate redundant const-key false negative — 2026-08-09

The second machine-gate run reached static validation but falsely reported the
Home and Book Table location keys missing. Both are arguments of const
`MoolServiceCard` invocations, so Dart format retains `key: Key(...)` and omits
the redundant nested `const`.

REG646 changes the gate to the formatter-stable token while the focused widget
test continues to mount both keys.
