# UAW C32O Buy router compact Mool launcher test successor preselection

Date: 15 August 2026
Ticket: `UAW-C32O-PERSONAL-MVP-BUY-ROUTER-COMPACT-MOOL-LAUNCHER-TEST-SUCCESSOR`
Classification: `mvp_supporting`

The accepted compact Shop shell renders `mool-compact-launcher`. C26D and C29N focused tests use that exact key. The old `buy_v2_router_test.dart` still uses `mool-home-launcher` in one helper and one direct assertion/tap, causing three cases to fail despite the compact runtime being present.

The smallest complete correction changes only those three test references and adds one successor checker. Runtime, references, Buy baselines, router behavior, backend/provider/build/Play/OPPO/credential and external-service state remain closed.
