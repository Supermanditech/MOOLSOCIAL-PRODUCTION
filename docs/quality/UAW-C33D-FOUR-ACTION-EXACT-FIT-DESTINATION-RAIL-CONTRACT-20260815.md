# C33D four-action exact-fit destination-rail contract

Version: C33D / 15 August 2026

A four-action local cluster requires 182 logical pixels: four 44-pixel cells
and three 2-pixel gaps. When the physical local rail is at least 182 pixels,
the cluster renders edge-to-edge and every action is directly hit-testable.
Token insets may reduce preferred geometry but may not force a physically
unnecessary viewport.

Only rails physically narrower than 182 pixels use bounded horizontal
overflow. Action order, labels, indicators, semantics, reduced motion, Mool,
family root and Chat remain unchanged. Responsive tests own their actual View
size and DPR so MediaQuery and render constraints cannot disagree.

This contract adds no screen, route, session, service, backend owner,
provider, payment, funds or live booking authority. Device and release
acceptance remain separately held.
