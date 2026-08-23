# Temporary navigation prototype first-viewport content occlusion rejection

Date: 2026-08-09

Founder evidence showed that the Shop Home prototype stacked its family label,
large title, explanatory copy, full search control and horizontal category row
before the discovery feed. At phone scale, the first product card began so low
that only a partial card was visible above the persistent bottom navigation.

Root cause: validation proved six category sets, 44px tap targets and valid
JavaScript, but did not measure cumulative top chrome or require meaningful
customer content in the first small-phone viewport.

Correction contract: each family Home has one compact top toolbar with fixed
Search and Chat access followed by horizontally scrollable categories. The
large heading, lead and full search field are removed from the pre-feed stack.
The toolbar moves out of the way on downward content scroll and returns on the
first deliberate upward scroll, with immediate reduced-motion behavior.

No Flutter source, accepted screenbook, APK, installed OPPO state or protected
runtime was changed by this temporary-HTML rejection.
