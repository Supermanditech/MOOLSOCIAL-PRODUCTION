# C29X compact Mool launcher stable-key compatibility test rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-CHAT-GLOBAL-EDGE-AND-CONTRAST-C29X`
- Result: focused Chat suite rejected, 3 failing tests

The compact edge rail correctly adopted the uniform `mool-compact-launcher` identity, but the new edge-contract test and two existing Chat journeys still searched for the old non-compact `mool-home-launcher` key. The complete focused suite was rejected. Exact source inspection proved the compact production key; the retry migrates all three affected Chat test references atomically and does not add a duplicate compatibility key. No build, install, device action, deployment or external write occurred.
