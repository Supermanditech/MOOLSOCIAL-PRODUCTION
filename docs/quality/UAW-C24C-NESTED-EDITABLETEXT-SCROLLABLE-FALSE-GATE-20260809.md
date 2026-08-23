# C24C nested EditableText scrollable false gate — 2026-08-09

The first focused C24C test run passed the cuisine-to-order and table-booking
journeys. All three adaptive cases were falsely rejected because the test
collected every `Scrollable` below the discovery ListView, including the
search field's framework-owned horizontal `EditableText` scrollable.

REG639 narrows the permanent contract to the keyed customer-facing ListView's
own `scrollDirection`. Internal text editing motion is not a horizontal page,
restaurant rail or subaction strip.
