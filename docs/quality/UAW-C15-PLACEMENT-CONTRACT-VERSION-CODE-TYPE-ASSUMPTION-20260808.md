# C15 placement contract version-code type assumption

Date: 2026-08-08

Regression ID:
`REG-20260808-294-C15-PLACEMENT-CONTRACT-VERSION-CODE-TYPE-ASSUMPTION`

A combined C15 placement-contract patch was rejected atomically because its
context assumed `rejectedCandidate.versionCode` was a JSON number. The live
contract stores the value as the string `"2026080712"`. The file remained in
its exact prior C14 state after the failed patch.

Root cause: a remembered semantic type was used as patch context instead of
copying the exact immediately inspected source text.

Permanent prevention: before every JSON state patch, parse the value to learn
its meaning and separately read the exact bounded source lines used as patch
context. Retry with small owner-specific hunks only; a rejected combined patch
never proves that any earlier hunk in that patch changed the file.
