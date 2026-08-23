# C24E shared primary-button Ahem glyph rejection — 2026-08-09

Manual inspection of the generated OPPO-class Doctor and Salon captures found
the fixed primary-action labels rendered as white Ahem glyph blocks. Other text
was legible, including the connected `MoolSocial` launcher.

`MoolServicePrimaryButton` repeated the already registered REG677 pattern: its
local FilledButton text style supplied size and weight but omitted the Inter
font family. The shared owner is corrected, both captures must be regenerated
and inspected, and the pre-correction captures are rejected as qualification
evidence.
