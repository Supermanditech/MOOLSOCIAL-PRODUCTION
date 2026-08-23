# Screen 03 element screenshot viewport-intersection clipping regression

- Regression: `REG-20260815-2475-SCREEN03-ELEMENT-SCREENSHOT-VIEWPORT-INTERSECTION-CLIPPED`
- Failure: the first screenshots contained only the visible intersection of the phone because the review header placed the target below the viewport origin.
- Impact: the clipped images are rejected as review evidence. The 84 responsive/state checks and nine interactions still passed; no source, provider, email, Hosting or device state changed.
- Prevention: scroll the exact phone target to the viewport origin before capture and assert captured PNG dimensions before accepting screenshot evidence.
