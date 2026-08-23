# REG3151 - Unattended machine-state patch not durable

## Classification

Registered initial false absence, corrected before retry with no duplicate mutation.

## Evidence

The earlier bounded patch result was unavailable after context compaction. The first projection queried the wrong top-level path and returned false. A complete parent-object readback then proved the object already existed at `comprehensiveSuccessorAudit.unattendedAutomation`; no retry occurred.

## Prevention

Treat truncated or compacted mutation output as unknown. Read back the exact nested object path before classifying absence, and never retry when the nested readback proves the object already exists.
