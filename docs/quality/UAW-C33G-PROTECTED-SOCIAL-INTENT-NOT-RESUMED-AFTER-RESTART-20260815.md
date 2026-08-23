# UAW C33G protected Social intent not resumed after restart

The focused FIX3 test proved that a signed-out production-style guest session could persist a protected shared-post Create intent and then reconstruct as ready instead of sign-in. Startup recognized only the YouTube connection path as a resumable authentication intent.

The repair remains inside JourneySession and its existing JourneyStore owner: persist the exact bounded local cancel route and purpose, classify only Chat, Social Create, protected Feed actions and YouTube connection as authentication intents, resume those after restart, and leave public Feed guest-readable.
