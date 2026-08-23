# C30T golden assets in source fingerprint — 2026-08-13

The invalidated C30T source manifest included Dart tests but omitted `apps/mobile/test/goldens/*.png`. Because visual baselines are executable test inputs, this could allow pixels to change without changing the sealed candidate fingerprint.

The comprehensive pre-AAB qualifier now inventories and hashes every PNG in the exact shared golden directory. Historical baselines remain preserved and the new inspected `chat-c30t-*` baselines become part of both identical qualification cycles.
