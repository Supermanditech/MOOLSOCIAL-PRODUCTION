# C16 PowerShell LiteralPath wildcard checksum recurrence

## Incident

The Ride/Cab-to-Bike predecessor motion frame sequence completed, all four PNGs
were pulled, and the final UIAutomator dump proved Bike selected. The reporting
step then passed `2*-ride-left-*.png` to `Get-FileHash -LiteralPath`, which
rejects wildcard syntax. Only the grouped checksum output failed; the captures
remain preserved and are not yet admitted by hash.

## Root cause and prevention

Literal-path mode and wildcard discovery were combined. C16 checksum reporting
enumerates exact files first and passes each resolved literal path separately to
`Get-FileHash`. A grouped checksum failure is discarded and no checksum is
claimed until the explicit-list retry succeeds.
