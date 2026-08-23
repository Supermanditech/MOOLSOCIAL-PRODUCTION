# C29N white edge-control internal-height overflow

Date: 2026-08-11
State: resolved; permanent prevention active
Regression: `REG-20260811-1226-C29N-WHITE-EDGE-CONTROL-INTERNAL-HEIGHT-OVERFLOW`

## Preserved observation

The first C29N focused widget run rendered the new globally white Mool and Chat
edge controls at 390x844. Each fixed 58-pixel control added an internal 3-pixel
card inset. After the existing icon-label padding, only 46-47 pixels remained,
and Flutter reported 5-6 pixel bottom overflows for both controls. The separate
320-pixel keyboard composer case passed in the same run.

## Root cause and prevention

The decorative inset changed usable content geometry inside an already fixed and
accepted rail height. The correction retains the full shared rail height for the
white Material surface, preserves its radius, learned edge positions and semantic
target, and removes only the redundant outer inset. The C29N focused widget gate
renders both controls and fails on any layout exception.
