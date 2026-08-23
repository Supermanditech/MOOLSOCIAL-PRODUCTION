# C21H clipped semantic center is not a valid touch center

Date: 2026-08-08

While Eat was current, a probe tapped the center of UIAutomator's clipped `Previous main actions` rectangle at y=1435. The resulting selected semantics showed Work / Earn Today, so the probe did not provide a controlled previous-navigation result and was rejected.

No screenshot pair from this probe is accepted. Device navigation will be calibrated against actual display coordinate mapping and painted geometry, with exact destination semantics required after every tap.
