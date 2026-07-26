# MoolSocial public web device proof

- Date: 26 July 2026
- Device: OPPO CPH2375
- Browser: Chrome
- Public URL: `https://moolsocial.com/`
- Release: `20260726-2`

## Evidence

- `01-public-root.png` — the public homepage loaded over HTTPS with the
  versioned production layout, complete three-phone scene and mobile
  navigation.
- `01-public-root.xml` — Android window hierarchy captured with the public
  domain visible in Chrome.
- `02-our-story-tap.png` — tapping `Our story` moved to the correct live
  section and displayed its selected navigation state.
- `03-contact-tap.png` — tapping `Contact` opened Android's email-app chooser,
  proving the `mailto:hello@moolsocial.com` destination is actionable. The
  chooser was dismissed without sending a message.

Automated release tests validate every remaining public link destination.
