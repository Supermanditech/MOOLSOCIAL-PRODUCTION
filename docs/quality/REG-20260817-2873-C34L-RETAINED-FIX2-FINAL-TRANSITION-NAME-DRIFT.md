# REG2873 — C34L retained FIX2 final transition-name drift

- Status: registered pre-test cross-owner defect.
- Defect: the retained fixture and new final-proof expectation used `journeys-accepted`, while the authoritative transition owner emits `device-accepted` for the journey phase.
- Root cause: the old retained gate did not validate transition identity, so a locally copied fixture label drifted from the lifecycle owner's exact ValidateSet and proof output.
- Prevention: derive/bind every retained final-proof transition name directly from the authoritative transition contract, require `device-accepted`, add a wrong-transition negative, and qualify the connected retained/transition interface on both PowerShell hosts.
- Impact: detected during readback before behavior retry; no recovery, release, device, private, or external action.
