# C17C test-root inventory lookup rejection

Date: 2026-08-08
Next ticket: `UAW-PERSONAL-MVP-SOCIAL-BUY-CLEAR-GLASS-CONFORMANCE-FIX2-C17C`

The first bounded Social/Buy coverage search included
`apps/mobile/test/features`, which does not exist. Ripgrep rejected that one
root while returning results from `apps/mobile/test/ui_v2`. No conclusion is
drawn from the rejected root. C17C uses `rg --files apps/mobile/test` to derive
verified test paths before any further content search.
