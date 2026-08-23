# C30U enumerated release schema ignored in projection

## Incident

The state inspection printed the exact C30U schema but its value projection in
the same command still used prior-schema field names. Required values returned
null and are rejected as evidence.

## Root cause

Enumeration and projection were composed before the actual property list was
available, so stale expressions survived after the mismatch became visible.

## Permanent prevention

Run schema enumeration first. In a separate command, project only exact fields
returned by that enumeration and assert every required value is non-null.

No build, deployment, upload, install or device mutation occurred.
