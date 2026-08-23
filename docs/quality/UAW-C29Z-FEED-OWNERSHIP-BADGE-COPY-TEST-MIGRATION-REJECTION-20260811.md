# C29Z Feed ownership badge copy test migration rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PUBLIC-FEED-TIMELINE-AND-POST-CTA-C29Z`
- Result: combined Social suite rejected, 43 passing and 1 failing case

The compact Feed header replaced the large `MOOL OWNED` badge with the clearer `PUBLIC FEED` label, but one continuous Social assertion retained the removed copy. All other Screen 04 and customer-copy cases passed. The retry updates the exact Feed test to the compact brand key, new label and truthful empty posting action, then reruns the affected suites. No build, install, device action, deployment or external write occurred.
