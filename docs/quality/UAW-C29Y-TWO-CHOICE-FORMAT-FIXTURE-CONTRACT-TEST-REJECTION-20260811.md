# C29Y two-choice format fixture contract test rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-POST-READY-CREATE-AND-FOUR-CHOICE-POLLS-C29Y`
- Result: focused Create suite rejected, 1 failing test

Three direct-composer/Create tests passed. The remaining format-rendering test used a later helper that still generated two-choice poll and quiz fixtures. The production session correctly rejected those samples under the new four-choice contract; the test then failed while looking up an unpublished item. The retry inventories every `SocialPublishedChoice` construction in that exact test owner, migrates accepted fixtures to four complete choices and retains an explicit negative two-choice assertion. No build, install, device action, deployment or external write occurred.
