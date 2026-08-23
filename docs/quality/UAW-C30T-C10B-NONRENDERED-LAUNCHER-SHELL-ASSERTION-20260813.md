# C30T C10B non-rendered launcher-shell assertion — 2026-08-13

After the retired Feed child key was corrected, the focused C10B rerun passed the authenticated Feed owner and durable compact launcher assertions, then failed because it also required `moolsocial-single-home-launcher-shell` on the Social Feed projection. Production source still owns that wrapper for projections that use it, but the current Social Feed root renders the public `mool-compact-launcher` without that conditional wrapper.

No product source or navigation behavior failed. The bounded correction is to retain the durable launcher, destination and return-owner assertions and remove only the projection-internal wrapper assertion from C10B before retrying.

## Resolution

The conditional wrapper assertion was removed while the durable `mool-compact-launcher`, Social/Work destination owners, hidden legacy global navigation, and exact Back-to-Feed assertions remain. The focused journey passes.
