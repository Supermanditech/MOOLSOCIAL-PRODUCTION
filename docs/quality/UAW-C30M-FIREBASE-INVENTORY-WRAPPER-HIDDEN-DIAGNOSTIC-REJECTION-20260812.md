# C30M Firebase inventory wrapper hidden-diagnostic rejection

- ID: `REG-20260812-1442-C30M-FIREBASE-INVENTORY-WRAPPER-HIDDEN-DIAGNOSTIC-REJECTION`
- Date: 2026-08-12
- Scope: read-only Firebase Functions inventory
- Result: nonzero child with no usable Firebase diagnostic; no cloud mutation occurred

The JSON-capture wrapper observed a nonzero Firebase child exit but surfaced
only its own exception, hiding the provider diagnostic needed to distinguish
authentication, project and CLI failures. No empty inventory inference is
accepted. C30M retries the exact read-only Firebase command directly first,
then parses only after the child succeeds.
