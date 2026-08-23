# C30T Feed share false-success finding

Date: 2026-08-13

The real Feed Share sheet reports `MoolSocial link copied` without calling `Clipboard.setData` and without receiving the selected post. Its Chat option merely opens Chat; it neither attaches nor sends a post. Both are false-success paths on a reviewer-critical Social action.

The bounded correction exposes only one complete action: copy a stable HTTPS URL for the exact post, report success only after the clipboard write, and resolve the item through bounded Feed pagination when the link opens. A missing or removed post must produce a truthful recovery notice. Chat attachment/send, share-count mutation and a new backend owner are excluded.

The link depends on the separately recorded Android App Links and Hosting source correction. Hosting deployment, AAB, Play, OPPO, backend/provider and communication actions remain held.

## Local implementation and verification

- Feed Share now receives the exact provider post.
- The unimplemented Chat share option is absent.
- `Clipboard.setData` receives `https://moolsocial.com/app/social?sub=feed&item=<postId>` before `Post link copied` appears.
- A shared item beyond the first 20-post page is loaded through bounded pagination and presented first in Feed.
- A missing item leaves Feed usable and explains that the post may have been removed or is no longer public.
- focused Flutter result: 17 passed, 0 failed; SHA-256 `DF1B729E5314FBAE1DA6B6596EE5F2E14D1EAA1A4C05F4D9B5027CFC00B59ADC`.
- release registrant restored to exact 15 plugins; existing APK/AAB unchanged.

Live usability remains blocked by the separately held Hosting deployment.
