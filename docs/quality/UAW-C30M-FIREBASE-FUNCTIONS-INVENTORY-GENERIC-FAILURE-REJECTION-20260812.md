# C30M Firebase Functions inventory generic-failure rejection

- ID: `REG-20260812-1443-C30M-FIREBASE-FUNCTIONS-INVENTORY-GENERIC-FAILURE-REJECTION`
- Date: 2026-08-12
- Scope: read-only Firebase Functions inventory
- Result: Firebase CLI returned `Failed to list functions`; no cloud mutation occurred

The direct installed Firebase CLI inventory returned only a generic project
failure despite the already-confirmed gcloud account and project. It is not
accepted as empty deployed state and is not repeatedly polled. C30M switches
to the authenticated installed gcloud Functions v2 read-only surface for exact
service metadata, while retaining Firebase CLI deployment as a separately
qualified later gate.
