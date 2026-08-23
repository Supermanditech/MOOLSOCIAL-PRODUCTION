# C29U Firebase search accessibility focus mismatch rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-DEV-BACKEND-DEPLOYMENT-C29U`
- Regression: `REG-20260811-1296-C29U-FIREBASE-SEARCH-ACCESSIBILITY-FOCUS-MISMATCH-REJECTION`

The accessibility index labelled `Search products and features` was clicked,
but the refreshed `focused_element` identified Chrome's address bar. The focus
verification stopped the flow before any text was typed, so no URL, project or
cloud state changed.

With the address bar now explicitly verified, the recovery may navigate only
to the exact authorized Dev Firebase Storage URL. Every later field receives a
fresh focus check before typing.
