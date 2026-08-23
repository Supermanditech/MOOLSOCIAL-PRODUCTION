# C30O Play Integrity roles/browser server-side link rejection

Date: 2026-08-12

## Observed result

After `user:supermanditech@gmail.com` received project-level `roles/browser` on `moolsocial-dev-503018`, Play Console resolved project number `760290687711` as `MoolSocial Dev Trial` and enabled `Link project`.

The one authorized link submission failed with the exact Play status:

`Project not found. Check it again or ask the project owner to add you as an owner of the project on the Cloud Console.`

## Classification

The earlier assumption that project discovery permission was the complete link prerequisite was false. `roles/browser` satisfies client-side visibility but not Play's server-side project-link authorization.

## Prevention

- Do not retry the same link with only `roles/browser`.
- Do not grant broad Cloud Owner solely from the UI error without qualifying Google's current official requirement and the smallest safe account topology.
- Prefer using the Cloud-authorized `hello@moolsocial.com` identity in Play Console if that avoids an unnecessary Owner grant to the consumer Gmail account.

## External state

- Play project remains unlinked.
- No Play Integrity response setting changed.
- The founder-created `roles/browser` binding remains present.
