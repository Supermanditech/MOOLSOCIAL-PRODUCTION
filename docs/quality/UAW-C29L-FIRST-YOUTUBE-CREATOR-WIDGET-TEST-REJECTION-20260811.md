# C29L first YouTube creator widget-test rejection

The first C29L focused widget batch found three native presentation defects at 412×915: the connected-status row overflowed by 30 pixels, radio/checkbox/list tiles were placed above a colored `DecoratedBox` without their own Material ink surface, and cancellation feedback existed only at the top of a long lazy list instead of beside the upload action.

The direct resumable uploader cancellation test passed. The permanent prevention is to test the exact OPPO-width viewport, give interactive tiles a local Material ancestor and render failure/cancel feedback at the action point as well as in the page summary. No build, device, provider or protected runtime changed.
