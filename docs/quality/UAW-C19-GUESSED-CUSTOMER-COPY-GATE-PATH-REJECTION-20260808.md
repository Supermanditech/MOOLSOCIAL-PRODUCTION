# C19 guessed customer-copy gate path rejection

Date: 8 August 2026

Ticket: `UAW-PERSONAL-MVP-SCREEN03-PROFILE-PROVENANCE-TEST-LOCK-RECONCILIATION-FIX1-C19`

State: **REJECTED; INVENTORY REQUIRED BEFORE RETRY**

The first C19 parameter inspection read the existing device-review runtime gate
but then queried a guessed `scripts/check-customer-copy-machine.ps1` path that
does not exist. The mixed command exited nonzero. The runtime-gate inspection
still proved that it clears logcat, force-stops/starts the installed app and
requires the exact newly installed candidate marker, so it is correctly
deferred until the authorized successor device candidate exists.

The missing copy-gate path is registered as REG-386 before discovery. Script
owners must be selected from `rg --files scripts` rather than reconstructed
from prose labels in historical tickets.
