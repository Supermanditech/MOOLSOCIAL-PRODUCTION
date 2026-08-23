# C25F C13 route-alias equality rejection

Date: 2026-08-09

The first migration introduced a literal route equality that does not belong
to the product contract. Social uses `/app/social` as the canonical main route
and `/app/social?sub=shorts` as its explicit default local route. Both resolve
to the same Screen04 owner. C13 must prove the declared main projection and the
observable owner/local-rail outcome without collapsing valid aliases.
