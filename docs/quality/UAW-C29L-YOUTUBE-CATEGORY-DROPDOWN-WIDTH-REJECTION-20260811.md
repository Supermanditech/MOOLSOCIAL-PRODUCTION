# C29L YouTube category dropdown width rejection

The second focused C29L widget run cleared the channel-status and Material-surface defects but found the category `DropdownButtonFormField` overflowed by 33 pixels at 412×915 because it did not use expanded layout.

The permanent prevention is to set `isExpanded: true` on long-label dropdown fields inside mobile card padding and keep the exact OPPO-width widget gate. No build, device, provider or protected runtime changed.
