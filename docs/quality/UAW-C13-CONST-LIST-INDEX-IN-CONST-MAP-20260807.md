# C13 const-list index in a const map

Date: 2026-08-07

Regression:
`REG-20260807-272-C13-CONST-LIST-INDEX-IN-CONST-MAP`

## Failure

The first focused C13 analyzer run rejected four test-only map values because
the const `retiredChoiceRoots` map indexed the const `defaultLandings` list.
Dart does not treat the index expression as a constant map value.

## Prevention

When a test reuses records by indexing an existing const collection, the
derived lookup is top-level `final`, not `const`. Exact analyzer qualification
remains mandatory before any widget test or build. No app runtime source was
affected by this analyzer rejection.
