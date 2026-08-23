# C30K Firebase path guess rejection

## Finding

The read-only social-content owner inventory included an inferred repository root named `firebase`, but that path does not exist. The valid owner inventory returned before the path error is retained only as discovery context, not as a passed gate.

## Disposition

Rejected and registered as `REG-20260812-1399-C30K-FIREBASE-PATH-GUESS-REJECTION`.

## Permanent prevention

Use the repository file inventory to discover exact service, rules and configuration paths before narrowing an owner search. Never add a conventional backend directory name from memory.
