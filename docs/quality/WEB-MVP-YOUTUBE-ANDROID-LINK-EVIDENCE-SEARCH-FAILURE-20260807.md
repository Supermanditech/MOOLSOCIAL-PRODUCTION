# YouTube Android-link evidence search failure

Date: 7 August 2026
Regression: `REG-20260807-128-RETAINED-ARTIFACT-ROOT-SEARCH-UNBOUNDED`

A read-only lookup for the submitted YouTube review APK identity and Firebase
App Distribution history used bounded exact text but an unbounded repository
root. The production workspace contains very large retained artifact trees, so
the command timed out without producing readiness evidence. No source, build,
device, Firebase, provider or email state changed.

The retry is restricted to known `config`, `docs/quality` and exact candidate
evidence owners. Large retained evidence is discovered by filename first and
searched only with narrow path and filename filters.
