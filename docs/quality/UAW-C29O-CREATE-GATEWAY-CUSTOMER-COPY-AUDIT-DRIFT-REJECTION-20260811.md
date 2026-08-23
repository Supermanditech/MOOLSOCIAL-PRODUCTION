# C29O Create gateway customer-copy audit drift rejection

## Rejection

The broad protected Flutter suite rejected the Screen 04 customer-copy audit
because it expected `social-v2-create-workbench` immediately after mounting the
default Create destination.

## Cause

The accepted C29N journey opens `social-creator-gateway` first so a customer can
choose between YouTube-hosted Shorts creation and MoolSocial-hosted posting. The
older audit had not been migrated with that ownership boundary.

## Permanent prevention

The audit now proves the gateway, taps `social-create-moolsocial-post`, then
audits the MoolSocial composer and prohibited commentary copy. This preserves
the accepted journey without adding a tap or a fake success state.
