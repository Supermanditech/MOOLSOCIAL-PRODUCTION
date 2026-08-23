# C13 Ride in-place type switch test expected Back history

Date: 2026-08-07

Regression:
`REG-20260807-274-C13-RIDE-IN-PLACE-TYPE-SWITCH-TEST-EXPECTED-BACK-HISTORY`

## Failure

After the stale chooser migration, the focused FIX2 file passed 22 cases and
failed only Ride Auto and Cab. The test correctly selected each type but then
expected system Back to restore Bike.

## Root cause and prevention

Ride Bike, Auto and Cab share the existing booking owner. Its local rail
updates `RideSession.selectedType` in place and intentionally does not push a
duplicate booking route. Tests therefore do not invent history for a valid
in-place type switch. They prove the selected Ride type directly and retain
the separate Chat and Mool round-trip cases that must restore that exact type.
