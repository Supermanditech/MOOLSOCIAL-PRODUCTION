# C24C Fix1 Eat connected-action id mismatch rejection — 2026-08-09

The first Fix1 migration built the Home key with historical projection id
`order-food`, while the connected chooser's compact internal action id is
`order`. Labels and routes agree; internal owner ids are not interchangeable.

REG661 keeps projection parity independent and uses the connected owner's
stable id for connected chooser interaction.
