# C33E combined small/large auth document read truncation

Date: 15 August 2026
Regression: `REG-20260815-2340-C33E-COMBINED-SMALL-AND-LARGE-AUTH-DOC-READ-TRUNCATED`

An authentication diagnosis read combined the complete small C30T Dev
provider-configuration record with the large append-only C30T findings owner.
The combined output was truncated. The partial large-document output is not
accepted as evidence and will not be retried in full. Future inspection uses
only exact targeted ranges or parsed searches. The independently complete
small record remains valid. No product, device, build, provider or external
state changed.
