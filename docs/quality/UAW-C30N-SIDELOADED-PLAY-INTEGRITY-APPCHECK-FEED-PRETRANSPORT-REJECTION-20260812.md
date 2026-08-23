# C30N sideloaded Play Integrity/App Check Feed pre-transport rejection

The C30N gate allowed one checksum-matched ADB profile install, but did not
prove that this off-Play distribution channel could satisfy the Dev Firebase
App Check Play Integrity policy before consuming the build and install.

On OPPO, the real Feed failed before any `moolSocialContent` request reached
Cloud Run. The installed package reports installer `pc` on Android 13. The
private App Check verdict was not accessed, so Play recognition is retained as
the evidence-backed leading cause rather than asserted as a decoded verdict.

Permanent prevention: before any successor build, bind the intended install
channel to the exact App Check acceptance policy and prove the channel is
eligible. For a production-grade candidate, use a Google Play-recognized
internal-test artifact/install. Never issue Create writes until the same
signed-in client has completed an authoritative live Feed read.

Primary evidence:
`docs/quality/UAW-PERSONAL-MVP-SOCIAL-PUBLIC-FEED-CREATE-OPPO-QUALIFICATION-C30N-DEVICE-REJECTION-20260812.md`.
