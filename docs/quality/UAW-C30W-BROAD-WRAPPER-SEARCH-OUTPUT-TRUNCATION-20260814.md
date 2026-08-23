# C30W broad wrapper search output truncation

## Rejected attempt

The interrupted C30W inspection queried several broad terms across the exact
PowerShell wrapper and emitted too much embedded gate text. The tool output was
truncated and is not admissible evidence for the wrapper contract.

## Root cause and permanent control

The owner was already known. Future wrapper inspection must locate one exact
token, capture only its scalar line number, and read a small numeric range. A
broad multi-token source rendering may not be used to qualify a release gate.

No build, upload, install, provider action, or secret access occurred.
