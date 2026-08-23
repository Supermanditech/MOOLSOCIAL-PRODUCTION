# C30W Flutter analyze repository-root evidence sweep

The first C30W analyzer command ran from the repository root rather than
`apps/mobile`. Flutter therefore inspected retained historical quality
artifacts, including intentional rejected and mutated fixtures, and reported
15,999 irrelevant issues with truncated output. That run is rejected as mobile
source evidence.

The only current C30W source finding in the bounded first output was an
unnecessary Foundation import, which was removed. Repository PowerShell gates
and the Flutter analyzer must run as separate commands from their correct
roots. No evidence was deleted or changed, and no build, upload, install,
service action, device mutation or secret access occurred.
