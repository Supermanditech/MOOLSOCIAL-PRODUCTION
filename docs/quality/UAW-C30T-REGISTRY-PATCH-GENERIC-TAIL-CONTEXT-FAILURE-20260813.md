# C30T registry patch generic tail context failure — 2026-08-13

## Outcome

The first registry append patch failed verification because its generic tail
context did not exactly match the JSON file. The patch tool made zero mutation.

## Root cause and prevention

The patch relied on generic closing braces instead of a unique current-tail
anchor. Registry-tail changes now anchor on the exact evidence path of the
last entry and include the complete closing structure in the reviewed patch.

Because this registry evidence is source-sealed, both no-AAB qualification
cycles must be repeated before build authority can be activated.
