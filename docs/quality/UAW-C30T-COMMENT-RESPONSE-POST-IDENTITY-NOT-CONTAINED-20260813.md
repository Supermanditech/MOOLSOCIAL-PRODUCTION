# C30T comment response post identity was not contained

- Regression: `REG-20260813-1970-C30T-COMMENT-RESPONSE-POST-IDENTITY-NOT-CONTAINED`
- Ticket: `UAW-C30T-PRE-AAB-FEED-COMMENT-REPLY-DEAD-END`
- Finding: production containment gap found during pre-AAB source audit.

The backend response contains a `postId` for every comment, but the Dart model
discarded it. The gateway also accepted an acknowledged post without proving
that its id matched the requested Feed post. A stale or malformed response
could therefore be rendered under or upserted into the wrong item.

The correction preserves comment `postId` and rejects mismatched comment pages
and reply acknowledgements before SharedSession mutation. This incident does
not authorize an AAB, upload, install, deployment or device mutation.
