# C30K text-poll undefined Firestore field rejection

## Bounded readback

After the first apply stopped, exact deterministic readback found:

- 3 of 3 disabled Dev Auth personas;
- 4 of 36 publish idempotency records;
- 4 of 36 post records, with no missing referenced post;
- 8 expected-prefix Storage objects;
- no Auth, Firestore or Storage readback error.

The sealed publish order means those four records are Asha's text post, image post, carousel and Image Poll. Their media cardinality is exactly `0 + 1 + 3 + 4 = 8`. The next record is a Quick Poll.

## Root cause

`FirestoreSocialContentRepository` emitted `image: undefined` for every choice without a media slot. Firestore rejects undefined document fields. Image Poll choices had real image objects, so the defect first became reachable at the Quick Poll boundary.

## Disposition

Rejected and registered as `REG-20260812-1408-C30K-TEXT-POLL-UNDEFINED-FIRESTORE-FIELD-REJECTION`.

## Permanent prevention

Omit the `image` property when no choice media exists and add a repository test that recursively fails if a four-choice Quick Poll document contains any undefined field. Keep the existing three personas, four posts and eight media objects; deterministic Auth identities and post idempotency must reconcile them without overwrite, deletion or duplication.
