# C17C first Social/Buy focused-test rejections

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-SOCIAL-BUY-CLEAR-GLASS-CONFORMANCE-FIX2-C17C`

The first C17C focused run failed and authorizes no ticket advancement.

## Social assertion scope

The test rejected any `FittedBox` below the Social rail. The two retained
YouTube provider SVG widgets legitimately use internal fitted rendering, so
that owner-wide assertion falsely rejected the provider assets. The design
contract forbids label shrinking, not correct SVG containment. The retry must
check every real label's ancestor chain and retain the two provider SVGs.

## Buy full-route text-scale scope

The test injected 200% system text into the complete Buy route. Unrelated
preexisting catalogue cards and global-dock tiles overflowed, including owners
outside the authorized subaction ticket, and produced fourteen rendering
exceptions. No local-rail defect was isolated by those errors. The C17 contract
sets the navigation acceptance threshold at 130%; full-route conformance uses
that threshold, while the isolated shared local rail retains its separate 200%
system-text test and internal 130% clamp. No unrelated Buy catalogue/global
rail mutation is authorized by this disposition.
