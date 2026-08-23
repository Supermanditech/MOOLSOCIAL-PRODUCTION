# C21 C21C gate rejected valid C21D successor state — 2026-08-08

The first C21D aggregate gate run called the C21C predecessor gate. C21C required the contract state to equal its transient `c21c` value, so it rejected the valid `c21d` advancement even though Social's exact qualified disposition remained present. C21D focused analysis and 2 tests had passed; the failed aggregate run is not accepted.

Sequential predecessor gates accept their own state and later C21 states while continuing to require their immutable family-qualification field. They must still reject earlier, missing or unrelated states.
