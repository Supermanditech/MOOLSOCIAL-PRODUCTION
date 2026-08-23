# REG3184 - Android resource audit guessed absent source sets

## Classification

Registered read-only audit-path rejection with partial bounded output and zero
source repair, build, APK, install or device action.

## Evidence

The first REG3182 resource search named `app/src/debug/res` and
`app/src/profile/res` without first proving those directories exist. `rg`
returned native exit 1 for both paths while also reporting main-source matches.
The partial output is not accepted as a complete resource audit.

## Prevention

Enumerate live Android source-set resource roots first. Pass only verified
directories to reference searches, or search from the verified `app/src` parent
with bounded build-directory exclusions. Never treat mixed match/error output as
complete audit evidence.
