# C30T C10B removed Feed thumb-composer key — 2026-08-13

The C10B global-navigation test fails before and after its Work round trip because it searches for `screen04-feed-thumb-composer`, a key no longer present in production source. C30T now exposes `screen04-moolsocial-feed-brand` and state-specific Feed owners. The navigation acceptance must use the durable current Feed owner while leaving the product implementation unchanged.

## Resolution

Both pre- and post-Work assertions now use `screen04-moolsocial-feed-brand`. The focused journey proves the Feed owner, opens Work through the shared launcher, returns with Android Back, and proves the same Feed owner again.
