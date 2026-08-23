# C24C metadata-fix multifile patch rejection — 2026-08-09

The first REG642 correction patch was rejected atomically because its runtime
hunk used pre-format context while also combining registry and evidence edits.
REG643 reapplies the permanent REG631 discipline: durable registration first,
then one freshly anchored runtime-source patch.
