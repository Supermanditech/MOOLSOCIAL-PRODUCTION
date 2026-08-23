# Temporary navigation prototype duplicate family-action gateway rejection

Date: 2026-08-09

The REG859 mixed-feed revision removed category selection, but standard family
Homes still contained a `Start in Shop/Food/Travel/Care/Work` action grid. That
grid duplicated the persistent bottom subaction rail and made the customer
choose a family mode before reaching the actual product or service.

Root cause: the earlier action launcher was retained after the feed became the
primary discovery owner, leaving two parallel navigation layers.

Correction contract: every family Home card represents the actual product,
restaurant, ride, care provider or work opportunity and opens its exact detail
or booking state in one tap. Remove the entire `Start in` grid. The persistent
bottom rail remains available only when a customer intentionally changes the
family mode; it is never a prerequisite for using a feed item.

No Flutter source, accepted screenbook, APK, installed OPPO state or protected
runtime was changed by this temporary-HTML rejection.
