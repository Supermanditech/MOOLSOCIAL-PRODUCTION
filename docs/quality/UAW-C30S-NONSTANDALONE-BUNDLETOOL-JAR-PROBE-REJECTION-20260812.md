# C30S non-standalone bundletool JAR probe rejection

Date: 2026-08-12

The first resource-dump probe invoked a Gradle-cached `bundletool` Maven JAR
with `java -jar`. It exited `1` before reading the preserved predecessor AAB;
no artifact, device or external state changed.

The Gradle cache artifact is not assumed to be a standalone CLI distribution.
Postbuild proof must first qualify its inspector against the preserved
predecessor, restrict output to the exact named resources, and pin the
inspector identity in provenance.
