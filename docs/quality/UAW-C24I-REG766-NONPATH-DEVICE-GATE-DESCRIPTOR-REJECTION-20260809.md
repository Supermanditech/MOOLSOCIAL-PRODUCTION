# C24I REG766 non-path device-gate descriptor rejection

Date: 2026-08-09

The first REG766 record used a conceptual OPPO device-matrix identifier in its `gates` array. The permanent regression-memory validator correctly rejected it because gate owners must be existing repository paths.

REG766 now points only to existing machine-readable repository gate owners. The OPPO-specific condition remains fully recorded in REG766 text and its retained screenshot/XML evidence. No device or installed application state changed during this correction.
