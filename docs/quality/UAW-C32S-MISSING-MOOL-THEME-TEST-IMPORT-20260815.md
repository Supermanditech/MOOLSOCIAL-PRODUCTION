# C32S missing Mool theme test import

Regression: `REG-20260815-2282-C32S-MISSING-MOOL-THEME-TEST-IMPORT`

The first C32S focused invocation stopped while loading the migrated C22F test.
The new assertion used `MoolColors.navy`, but the test had not imported the
`mool_theme.dart` library that owns that symbol. No test body ran and no
production source changed.

The exact theme import is added under C32S test-only authority. The source hash
must be rebound in the C32S gate, regression memory and both PowerShell hosts
must pass, and analyzer must compile the test before the focused Flutter retry.
