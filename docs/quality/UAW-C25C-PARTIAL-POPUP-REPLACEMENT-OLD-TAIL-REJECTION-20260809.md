# C25C partial popup replacement retained old tail — rejection

Date: 2026-08-09

Pre-test source inspection found two defects in the first C25C mutation: an obsolete family/subaction/Chat body tail remained after the new `MoolConnectedActionNavigator` class, and the new `MoolMainDomainMenu` call used the predecessor argument name `initialFamilyId` instead of `selectedFamilyId`.

No formatter, compiler or widget test was run against this malformed state. The exact old tail must be removed, the named argument corrected and the full class boundary reinspected before testing.
