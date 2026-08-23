# C16F generated Doctor-control static-gate rejection

The first C16F static gate looked for a literal
`const Key('doctor-care-clinic')` in production. `DoctorBookingScreen` instead
builds the care actions from `DoctorCare.values` and assigns the stable key
`doctor-care-${care.name}`. The concrete Clinic key exists only after runtime
expansion.

The checker now proves the generated production owner and inventory. The
focused widget test remains responsible for proving that the concrete Clinic
control is present, hit-testable and restored after Back.
