# C29N three-fixed-cell compact-width fitment rejection

Date: 2026-08-11
State: resolved; permanent prevention active
Regression: `REG-20260811-1227-C29N-THREE-FIXED-CELL-COMPACT-WIDTH-FITMENT-REJECTION`

## Preserved observation

C29N host cycle 1 passed its ticket, regression, MVP scope, format and full
Flutter analysis gates. The 17-file protected test batch then recorded 12
failures. At 320x568 and 140 percent text, the common destination rail contained
three 54-pixel fixed cells (Mool, family root and Chat) plus gaps, leaving less
than the local rail's required 182 logical pixels. The shared design assertion
rejected the layout, first reported for `ride/bike`. No cycle evidence was
written and no build, device, backend, provider or secret operation occurred.

## Root cause and prevention

The successor rail added Chat without adapting the combined fixed-cell width at
the smallest supported viewport. The correction applies the existing 44-pixel
minimum consistently to all three fixed cells at widths up to 340 pixels and
retains the accepted 54-pixel width above that boundary. The full rail remains
edge-stable, semantic targets remain at least 44 pixels, and exact 320x568/140%
coverage is now owned by C29N as well as the protected Screen 04 matrix.
