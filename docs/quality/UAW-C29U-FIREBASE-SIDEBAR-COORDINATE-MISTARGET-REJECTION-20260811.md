# C29U Firebase sidebar coordinate mistarget rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-DEV-BACKEND-DEPLOYMENT-C29U`
- Regression: `REG-20260811-1295-C29U-FIREBASE-SIDEBAR-COORDINATE-MISTARGET-REJECTION`

The first screenshot-coordinate action intended for `Databases and storage`
expanded `Hosting and serverless`. The refreshed tree and screenshot exposed
the mismatch immediately. No product was opened and no cloud resource, rule,
billing state or setting changed.

The retry uses the refreshed accessibility owner for the intended category and
verifies the resulting submenu before selecting Storage. Coordinate output is
never accepted as success without the refreshed visible and semantic outcome.
