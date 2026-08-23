# UAW C30T continuous Social audit checkpoint 04 — 2026-08-13

## Identity and holds

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`
- Candidate: `1.0.0-r60.45 (2026081345)`
- Build/upload/install: not authorized, counts `0/0/0`
- OPPO `2b3e0f71`: Play-installed `1.0.0-r60.44 (2026081244)`, exact installer `com.android.vending`
- No AAB, APK, upload, install, data-clear, downgrade, provider write, Hosting deployment or external communication occurred.

## Corrections proved in this checkpoint

1. Chat and Create asynchronous context use now has explicit mounted ownership.
2. Explicit Feed loading/error/unavailable states retain their complete
   progress or retry UI even if an asynchronous content owner has cached data.
3. Normal failed Feed refresh still renders cached posts, its failure notice
   and the exact cached retry.
4. Production routes and Social Create are source-locked against accidental
   YouTube upload reachability; the existing upload harness remains test-only.
5. Android reviewer controls and the public privacy, support, disconnect and
   deletion pages now use one Google Account permissions destination.
6. The public YouTube review page no longer presents a stale July APK/date/hash
   or overclaims unqualified live evidence; it truthfully identifies private
   Google Play Internal Testing and defers exact identity until qualification.
7. The in-app YouTube disconnect confirmation now rechecks screen ownership;
   cancel preserves the connection and confirm refreshes to disconnected.
8. A new C30T-only unsent reviewer package preserves the valid private tester
   URL while holding artifact, OPPO, screencast, Gmail, quota and approval state.
9. Sitemap last-modified dates now identify only the three indexed reviewer
   pages changed on 2026-08-13; unchanged indexed pages retain 2026-08-07.
10. Provider catalogue headings now explicitly say “YouTube videos” and
    “YouTube Shorts” while MoolSocial-owned navigation remains unchanged.
11. Post-test Android registrant contamination is now fail-closed: final
    config-only plus an exact metadata/15-class verifier is mandatory in both
    source qualification and the single-AAB wrapper.
12. The live qualifier no longer hardcodes the old incompatible YouTube
    revision; it requires exact non-empty provider/callback identities from
    machine state after a separately authorized deployment seals them.
13. The two-cycle qualifier now requires the current complete backend result
    of 505 passes and zero failures rather than its obsolete 503 marker.
14. The release registrant verifier is now included in the source aggregate
    manifest and locked across qualification-to-build handoff.
15. YouTube attribution controls now require an exact provider handler and
    cannot silently fall back to generic YouTube Home.
16. Privacy, deletion, revocation help and Google-permissions controls are now
    visible before optional read-only Google consent as well as after connect.
17. Public privacy scope language now states exact `youtube.readonly` access
    and explicitly excludes upload and YouTube mutations.

## Verification

- Latest current-source qualifier-owned manifest after the additional Chat,
  Creator-containment, shared-navigation and compact-fitment corrections:
  368 passed,
  3 skipped, 0 failed across 57 files,
  `0800E1C74FEA2AF15EAFC15A7FC064DC7FE0F88DF51B9FA639AC5D996893D02C`.
- Latest full Flutter analyzer: no issues,
  `D02235513ED2AD7FEFD1166EC1B741048FBABEECCC7D589027C952612D5803A6`.
- Final qualifier-owned current Social/YouTube/Chat/global-navigation manifest:
  historical checkpoint before the later corrections; 345 passed, 3 skipped,
  0 failed across 56 files,
  `0C12A57550049E3AA6B7C4DD055CE780F3C154668A51370C20E1A0CFE5AFC218`.
- Flutter analyzer: no issues,
  `20F2FBA66FD55504112881BE7C1001B8A021B9C6633A1B60B5AE952B4B3B3553`.
- Async-context focused Flutter: 38 passed,
  `1357B25D15CB3C8E814BA8DC38DC2C9D84C28346550CDD3359AC59CAA1032CBD`.
- Feed-state focused Flutter: 19 passed,
  `F29B727F98BF2E1DDB68A5F5CDF25586033C436B51477695081F22791D03D8E1`.
- Expanded Flutter: 349 passed, 3 skipped, 0 failed across 57 files,
  `71115A25D3786DEA9A9C3AF0FE5FC53CC89D42CB4FCBA55ABB537CA8C404AA68`.
- Isolated backend: 505 passed, 0 failed,
  `9D71C8B3D42962637A810B4DD8143277FA82B99797196AC86DE0BEE51BE58460`.
- C30T reconcile gate passed,
  `F3038B1AE0F8A1F8C9DF58B0B12D3F67B67B11BF5588E92D2C450DB4EE2CB3C9`.
- C30T static release readiness passed (15 plugins, 5 permissions, 4
  providers, candidate AAB count 0),
  `E2516666C1B4E00CA9C8037F587388B5E8383030B963A0F42B9DF70DB5A4F2FC`.
- C30T wrapper static gate passed,
  `DFD77F8F3FA3A670C4C6B3DADC1EC20058845D7C33A89F210DD4FA8729A26F3A`.
- YouTube upload production-reachability lock: 61 passed,
  `8F381942F9EC6ABFA1BCC387CB5A053F3BE9A7D729EC076A109B805DCD2119B4`.
- Reviewer-control public-site lock: 7 passed,
  `994074921649F49BCCCC611D395605886ECEB148368E1F66C988CD3DE791B5AE`.
- Reviewer-control Flutter tap lock: 14 passed,
  `39AA2786A0102EA0998A7313A63E197B3C6E11978159E8035CC69B19ED6706B4`.
- Final Flutter analyzer: no issues,
  `63B1EE8541E42767019413F8BA94FB8DA85A9D6148F90E3B3C0943F37F355B81`.
- YouTube review-page truthfulness lock: 7 passed,
  `97697AB64DF6A29EB889D90D8EB11632CD2A461F72B14AF8970F94D4C9E47136`.
- YouTube disconnect lifecycle/state lock: 16 passed,
  `D2D2DC10B1ACE14AE5EAE93D683593AAED25C1611FDBCF9F17D9B258A17F720D`.
- Post-disconnect Flutter analyzer: no issues,
  `8E5FECC237C5B85F0D44AE5CA7BCA4B71D1774969F2072C3732023E3296D38C8`.
- C30T reviewer-package hold gate passed,
  `E4C87D23E1BE6BD5B6AD2F34599EB8BB5C3512F24EA310CBFB50CB4ECD04C8A8`.
- Reviewer-policy sitemap mapping: 7 passed,
  `314A954645FC0376C627F8530BFB8F65406BD401CA2BD4D9C3770A3484060827`.
- YouTube source-identification UI/runtime set: 11 passed,
  `0150FAB69B98BCA27A8647211F201763F76B57A2DB9ABF6DC23636D0998AD11D`.
- Post-identification Flutter analyzer: no issues,
  `3346AFE9E74674AF8280ABE0653AD51475FFFF9607002A64848CDCC8F668A25B`.
- Post-test registrant recovery: 10 tests passed; final 15 plugins,
  Integration=false, APK absent and sealed AAB unchanged,
  `E1301729CC0B96A57B0F235C0214AAF8769389AE5D309D2B844E1C61FE5240A7`.
- Hardened wrapper gate passed,
  `DFD77F8F3FA3A670C4C6B3DADC1EC20058845D7C33A89F210DD4FA8729A26F3A`.
- Hardened static readiness passed (15 plugins, 5 permissions, 4 providers,
  AAB count 0),
  `83F8E20612A7EDF23757873F6EB166549DBE879DDE4180E243645548D6344060`.
- C30T release-script syntax set passed,
  `D3DEE9DC2201545500A42FC6B42737FC73B4252905C0DD5E9A8AEB868DB5E7FE`.
- Final static readiness with machine-state provider revision contract passed,
  `B816E991461E9A927EC606CAABF1E2CAC4CBAE27DD3E384CCEB1D43D4EC44083`.
- Final qualifier/readiness syntax after backend-count alignment passed,
  `F8B46D857CB6431A4B33BE84414691E3D2AC1959231F8A663BB27D6C7FA8B0D8`.
- Final source-manifest helper coverage syntax passed,
  `321695F877164073B7C2F9A4F032A8494CE2B34CD7A9022DF053BCFE1F219509`.
- Exact YouTube attribution destination set: 10 passed,
  `B769D5DF03B65601DDAFEB2C941AA9A43669D0E5C47A5EFAF4FF686AEC2CBC13`.
- Post-attribution Flutter analyzer: no issues,
  `178D9182276233AAAE3DC0AD382E7F9F75D42B48617EE4AC3B3891C45F817CF4`.
- YouTube pre-consent user-control set: 17 passed,
  `7CBA4BAF3C1DACBB365F171D6C11911068530C6C1DED8DF79EF6B7C8B3994CE0`.
- Post-preconsent Flutter analyzer: no issues,
  `BAFB4903A7258622D9E93CD6E67BD0F206CBF00F1681FDF02A8734DFB39ABD15`.
- Privacy read-only scope-truth lock: 7 passed,
  `B23088029D5156D20789F8B00CFC65274886EB6F10469C537A44E58906ED13B0`.
- Chat production no-op elimination set: 14 passed,
  `1664B99A4B8248945764AC04C696FC888422A5852E4786227B1DBC16761B480D`.
- Post-Chat-hardening Flutter analyzer: no issues,
  `27EE9FDA50E2DD810F23A1B1339680E67E951FBECAE7761F40C32804C9E411BB`.
- Creator alternate-entry containment plus exact shared Chat return: 2 passed,
  `0467EAB4BDE85EBE28807570BD2FF9EAEEFB0E8415E79DD5FCD71E7FAA165BDB`.
- Complete shared vertical suite after global Chat correction: 20 passed,
  `FDA9B12689EC801A3126854C4AC9955E7D523903021BCD73A073402841B7DCF9`.
- Post-shared-navigation Flutter analyzer: no issues,
  `DB82A50BDB1316A81BFCE2DCFB14C83DC43D21A82CC65FA5ED26D58BEF10A9C1`.

## Preserved release evidence

The sealed and working C30S AABs remain byte-identical at 93,201,374 bytes,
SHA-256
`2B06AEE022AED4019AE88AF4278A218FEA4F14F3D49F94CDC591DA855458AD55`.
No release APK exists. The release registrant contains 15 plugins and no
`IntegrationTestPlugin`.

## Known independent holds

- The full live qualifier remains held because the local owner-connect and
  Hosting corrections are not deployed; no live-provider pass is claimed.
- The shared Social customer-copy test retains its pre-existing 2026-08-11
  hash `8BB8D600D9072C69543D38B8FC20868DA7F352CFB554D5891E624BF997351CF9`
  against the older immutable lock hash. C30T preserved it byte-for-byte and
  does not waive or rewrite the protected lock.
- A new AAB requires a separate founder authorization after the complete
  preparatory audit.

## Continuous audit correction: production Chat has no review sender

The release entry point already injected `ChatSession.production()` and every
production send used the authenticated Dev gateway, but the production
constructor still instantiated a dormant `ReviewChatSendGateway`. That
ambiguous no-op owner has been removed: only the explicit review constructor
can retain the review sender, production stores none, and a missing configured
sender fails closed. Production/review Chat tests pass 14/14 and analyzer is
clean. No message, backend or device write was performed. See
`config/uaw-c30t-chat-production-noop-gateway-elimination-ticket.json`.

## Continuous audit correction: alternate Creator entries contained

The Social account sheet was already contained, but shared Media and Workspace
cards still routed into prototype Creator Studio screens carrying YouTube
publishing-destination claims outside the declared reviewer use case. Those two
discoverable cards now route to the real MoolSocial Feed and Create workbench.
The separately permitted read-only YouTube channel connection route remains
unchanged, and the broader Creator workspace stays frozen. See
`config/uaw-c30t-creator-studio-alternate-entry-compliance-containment-ticket.json`.

## Continuous audit correction: shared hubs restore global Chat

Shared Activity, Settings and Workspace screens supplied an exact Chat return
route but did not mount the current global Chat companion, leaving Chat
unreachable there. The companion is now rendered without moving the existing
Mool launcher and returns to the exact originating shared route. The complete
shared vertical suite passes 20/20 and analyzer is clean. See
`config/uaw-c30t-shared-navigation-retired-chat-key-migration-ticket.json`.
