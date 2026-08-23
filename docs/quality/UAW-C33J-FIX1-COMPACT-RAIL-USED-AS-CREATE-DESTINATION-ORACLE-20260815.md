# UAW C33J FIX1 compact rail used as Create destination oracle

- Regression: `REG-20260815-2509-C33J-FIX1-COMPACT-RAIL-USED-AS-CREATE-DESTINATION-ORACLE`
- Evidence: both GoRouter provider and delegate were exactly
  `/app/social?sub=create`; no framework exception existed; the rendered tree
  contained `SocialUniversalV2` and `SocialCreateWorkbenchV2`.
- Mistake: the test nevertheless required the optional responsive compact-rail
  key as if it owned the Create destination.
- Prevention: assert the exact content owner plus both canonical router URIs.
- Boundary: no external service, build, Play or device state changed.
