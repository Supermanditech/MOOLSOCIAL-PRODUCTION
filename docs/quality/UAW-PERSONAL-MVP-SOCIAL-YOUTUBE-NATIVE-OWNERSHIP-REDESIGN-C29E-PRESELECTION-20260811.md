# C29E preselection assessment

Ticket: `UAW-PERSONAL-MVP-SOCIAL-YOUTUBE-NATIVE-OWNERSHIP-REDESIGN-C29E`
Classification: MVP supporting
State: founder disclosed and authorized for source/test execution only.

## Customer outcome

The Social home presents YouTube-hosted discovery and Shorts with a coherent, professional, edge-to-edge YouTube-attributed UI while MoolSocial Feed and creation stay unmistakably MoolSocial-owned.

## Smallest complete implementation

C29E does not add a route, screen, provider, player, backend, auth owner or post owner. The internal `videos` state remains a compatibility alias but is labelled Home. The existing Social dock is restyled and reordered as `Home · Shorts · + · Feed · Chat · Mool`; the center plus maps to the existing ownership gateway, while Chat and Mool stay one-tap global controls. The public client follows existing provider page tokens and stops after a bounded page budget or 20 eligible unique items.

The seven recent OPPO reference screenshots were inspected before selection. The design extracts hierarchy, density, ownership and reachability; it does not alter the official embedded player, obscure controls, fabricate YouTube writes or modify the HTML screenbook.

## Authority

Authorized now: Flutter Social runtime edits and focused tests/gates.
Not authorized now: backend/provider deploy, secrets, OAuth claim, upload success, APK build, OPPO install, Production/Staging, commit, push or external communication.

The installed r60.30 identity and all C29D/C28D evidence remain protected. Any future OPPO review build requires a separately registered checksum-unique successor after source completion and fresh host qualification.
