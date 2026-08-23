# C29L protected Create direct-workbench assumption rejection

The first protected Social batch reached the existing Create tests after the C29L host-choice gateway was wired. Eight cases still assumed the bottom `Create` action mounted `screen04-create-workbench` immediately, so text-entry and key assertions failed before choosing the new explicit `Create a MoolSocial post` action.

The product contract intentionally changed: the common `+` must distinguish YouTube-hosted Short creation from MoolSocial-hosted formats. The permanent prevention is to keep protected publication assertions but traverse the explicit hosting choice first; tests must not bypass or erase the ownership boundary. No build, device, provider or protected runtime changed.
