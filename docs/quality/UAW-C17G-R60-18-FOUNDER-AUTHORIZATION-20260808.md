# C17G r60.18 founder authorization

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-CUMULATIVE-OPPO-QUALIFICATION-BUILD-RECOVERY-FIX1-C17G`

After the C17F r60.17 guarded build invocation produced no APK and no install, the founder explicitly authorized continuing through OPPO testing and stated that final approval will be given after reviewing the result on the OPPO device.

This authority selects a new recovery successor with unique r60.18 identity. It permits prebuild evidence, then exactly one guarded profile build if every gate passes, then exactly one checksum/signature-qualified in-place install if postbuild and live-device gates pass. The build must run in a persistent execution cell with a build-appropriate initial yield and be monitored through the same cell to terminal completion.

It does not authorize runtime redesign, a second C17G build or install, uninstall, data clear, downgrade, protected-reference mutation, credentials, external communication, funds action, Production write, commit, push, deploy or promotion. Founder device acceptance remains pending until OPPO review.
