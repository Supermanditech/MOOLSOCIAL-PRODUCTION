# C24B3 direct action tap-height rejection — 2026-08-09

The migrated Buy accessibility test measured the shared connected-chooser action owner at 35 px, below the required 44 px target. Although its parent row was 60 px high, `Row` supplied loose vertical constraints and the keyed `DecoratedBox` shrink-wrapped to its content.

The shared `_MoolDirectActionButton` must expand through the full 60 px row. Focused Home and connected-navigator tests must measure each direct-action owner at or above 44 px before qualification.
