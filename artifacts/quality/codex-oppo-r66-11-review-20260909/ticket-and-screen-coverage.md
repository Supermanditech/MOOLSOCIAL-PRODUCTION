# r66.11 ticket and screen coverage

| Finding | Implemented | Local verification | OPPO |
| --- | --- | --- | --- |
| OPPO-S03-02 contact instructions |00995b0c; field-specific malformed phone/email/alternate validation before verification|9 focused cases, normal/200% keyboard captures, two final connected cycles|Pending new APK|
| OPPO-S07-04 / REG-4549 application-support draft scope |b5236a11; local application identity, drafts/replies/media/error, async/retry safety|A/B isolation, empty drafts, ordinary Chat, reset, newer edits, Work recovery and combined cycles|Pending new APK|
| REG-4550 error banner keyboard fit |b5236a11; actual48px dismissal plus bounded full error text|412x915/100%,320x568/200%,320x536/200% with220px simulated IME; edge dismissal and scope preservation|Native retest pending; physical200%/TalkBack separate|

No screen is closed solely from widget tests. Backend dependencies and seven additional unresolved exploratory assertions remain explicitly recorded in local-validation.md and the prior review ledger. Dashboard first-tap visual approval remains destination-by-destination.
