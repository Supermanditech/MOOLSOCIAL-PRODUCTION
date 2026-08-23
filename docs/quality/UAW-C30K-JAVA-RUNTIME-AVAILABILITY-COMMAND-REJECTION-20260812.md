# C30K Java runtime availability command rejection

## Finding

The Firebase CLI exists, but a combined dependency probe invoked `java` before resolving it. No Java executable is on the current PATH, so the command failed before any emulator was started.

## Disposition

Rejected and registered as `REG-20260812-1403-C30K-JAVA-RUNTIME-AVAILABILITY-COMMAND-REJECTION`.

## Permanent prevention

Resolve each required host executable first and run a version command only after discovery. Treat an absent Java runtime as a bounded Firebase Emulator qualification dependency, never as authority to bypass deny-all rules testing.
