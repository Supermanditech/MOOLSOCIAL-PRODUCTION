# UAW-C33F Android OAuth package / Play signer qualification

The Google Cloud OAuth detail page was inspected without reading the OAuth client-ID field. The selected relationship is an Android application, its package matches `com.moolsocial.app`, and its SHA-1 matches the Google Play App signing key when compared in transient memory.

No certificate value, OAuth identifier, account identifier, API key, token, password, nonce, private key, App Check material, or attestation payload is retained or emitted. This qualifies `android_oauth_package_play_signer_relationship`. The separate `web_server_client_mobile_relationship` remains pending.
