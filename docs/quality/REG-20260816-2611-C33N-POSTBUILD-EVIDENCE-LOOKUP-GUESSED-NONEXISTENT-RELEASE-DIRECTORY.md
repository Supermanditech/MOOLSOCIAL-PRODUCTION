# REG-20260816-2611 — C33N postbuild evidence lookup guessed a nonexistent release directory

Date: 2026-08-16 IST

After the single r60.52 AAB and its dual-host postbuild qualification passed,
a read-only lookup for the retained Internal Testing upload workflow supplied
`docs/release` to two `rg` invocations without first proving that directory
existed. Both invocations reported that the path did not exist. Later valid
search roots returned usable evidence, but their success cannot erase or mask
the incorrect path assumption.

The lookup did not inspect secrets, mutate source, upload to Play, touch the
OPPO or change any external system. Nevertheless, permanent regression memory
requires this mistake to be registered before any further release action. The
resulting post-seal registry change invalidates r60.52 promotion under its own
fail-closed rule. r60.52 therefore remains one successfully built AAB and zero
uploads, installs or device acceptances; its artifact must not be uploaded,
reused, repaired, rebuilt or promoted.

Future workflow discovery must inventory repository directories first with
`rg --files` or a literal `Test-Path`, then search only verified roots. Each
native search exit must be asserted immediately so a later successful search
cannot mask an earlier path failure.
