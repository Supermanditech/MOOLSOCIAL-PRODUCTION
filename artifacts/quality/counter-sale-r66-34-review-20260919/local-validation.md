# Counter Sale local qualification

## Current approved-v13 source qualification — v14

This section supersedes the older current-source claims below. Founder approved
all seventeen v13 local screens and authorized ticket Git/integration and one
gated nonproduction review APK. No physical-device acceptance is inferred.

Fresh full44-file cycles ran serially in process67241, terminal9949f7, exit0.
Each cycle passed2741 tests, skipped83 and failed0. Repeated cycles do not mean
5482 unique tests. The pre-existing protected-reference exclusion is unchanged.
No application/test source changed during either run; before/after snapshots
prove395 inputs and zero drift. Post-analysis verification also found zero drift.
The refreshed repository source-manifest SHA256 is
DD7B3E64F4D5E6DE9F296A596DB32C6B38263AED872DE8E432F1BAAA09CB1AC4.

Exact external task outputs, retained without overwriting prior cycles:

| Log | Result | SHA256 |
| --- | --- | --- |
| counter-sale-approved-v14-full44-cycle-01-20260919.log | 2741 pass / 83 skip / 0 fail | 0B7D7A86DCADAF0FC96066326365C167494705C2D932A53A4E902D443141839B |
| counter-sale-approved-v14-full44-cycle-02-20260919.log | 2741 pass / 83 skip / 0 fail | 9AC09C5DBB38BED0FBDDEE1E4AC6ED96F0AA986DBFB690C7CAE5DE9A4E48D5D2 |
| counter-sale-approved-v14-format.log | 8 files / zero changes / exit0 | 2EA9787D4ECE31A606056C94820218BCA5A65D55550292787C12E9F7E0DFE2C0 |
| counter-sale-approved-v14-analysis.log | full mobile analysis, no issues / exit0 | 38BF71103D519FA7B2F7FC5D5F0EE638278D288D617A6FC35EDEE223C088C669 |

Analysis process84006 terminal1c8b69 and approved UI lock process21428
terminal8fc0c7 both exited0. All these processes are terminal. Current registry
metadata is rebound after the frozen-source cycles; it does not change their
application input hashes. Integration, final candidate activation, package/build
qualification and checksum-matched OPPO testing remain pending. This record is
not authorization to bypass any remaining gate.

Additional current-source checks: user-facing copy process51953 terminaleee6a4
passed; approved commit coverage9549c4 passed18 approved/2 rejected ancestors;
pending-evidence predicate01220d admitted10/rejected180 cases; native-lock
predicate0229b7 passed1/rejected6 with unchanged projection; whitespace82bde5
passed. These controls do not substitute for integration or physical testing.

## Retained earlier qualification history

Full raw logs are preserved in
C:/Users/jisal/Documents/Codex/2026-09-19/restock-testing-in-store/outputs/.
These are host checks, not physical OPPO/founder acceptance.

Two exact 44-file current-contract cycles were run as the complete Store
atomic/layout pair plus the 42-file complement in the retained helper
work/counter-sale-connected-qualification.ps1. Each cycle: 2723 passed,
83 skipped, zero failures. Skips are not passes; repeated cycles are not unique
additional tests. Existing protected-reference exclusions were not expanded.

| Log | Result | SHA256 |
| --- | --- | --- |
| counter-sale-combined-regression-02-20260919.log | 1187 pass / 79 skip | 42A2893CDD214B0130B5F67FAD93238BF9EF994C0C14941CC4223C95FD2862EB |
| counter-sale-combined-regression-03-20260919.log | 1187 pass / 79 skip | 9636062914A75917A53D427FCC03DE8CD4AA0BD2565316D64E934C056C7721AD |
| counter-sale-connected42-cycle-01-20260919.log | 1536 pass / 4 skip | A80D18808E38D0B61E00AB44B7E2DC94881A63CFDFB327DB5A900D6E8D8158EE |
| counter-sale-connected42-cycle-02-20260919.log | 1536 pass / 4 skip | 98389DA50D963DC24664812EB2405D9510D47B63DD13295235E0D84BB1911069 |

After these cycles exactly two input files changed: invoice-PDF disclaimer text
became retailer-facing while retaining preview/nonpayment warnings, and one
non-rendered Buy comment changed 'for example' to 'such as'. No Buy executable
change is permitted by the exact baseline-comparison gate. Do not claim the
44-file cycles ran after these two changes. Follow-up checks:

| Log | Result | SHA256 |
| --- | --- | --- |
| counter-sale-pdf-default-20260919.log | 13 pass | 19804E43650A8CBFE86620705DDB68D0CDE81C523010F6C47FFFC3216F5E0234 |
| counter-sale-review-isolation-20260919.log | 12 pass, enabled review/PDF/Work/Chat isolation | 5AAD17A1692C00767783E827C258D3745D6589F874D239F1E1C29260656BDDD3 |
| counter-sale-copy-analysis-20260919.log | no analysis issues in both changed owners | D03138D19E35F56E4D92970E05DA1B323F190BC466577C39FB02F8E0AD2E12E5 |
| counter-sale-copy-coverage-20260919.log | copy passed; commit coverage 18 approved / 2 rejected | 32BEC6B4943F87B49E0EC2CB5968D0DDB9FB8CD634CF41AF321C017A52961FA0 |

Generated synthetic one-page and six-page PDFs were extracted and all seven
rendered pages inspected. New disclaimer is present, old wording absent, and no
clipping/overlap was observed. Source snapshot comparison verified exactly those
two changed inputs. Earlier failed assertions/gates and original logs remain
registered under REG-20260919-4631; no failure was deleted to obtain qualification.

Final aggregate build qualification, complete format/analysis evidence binding,
clean source seal, wrapper/package controls and physical device testing remain
pending. This record alone cannot authorize an APK build.

## Final format and analysis

Session16030 terminale06c78 exited0 after both commands. Read-only Dart format
checked all8 changed application/test owners: zero changes. Full mobile
`flutter analyze --no-pub` reported no issues. Logs in the external outputs:
- counter-sale-final-format-20260919.log SHA25688E06101E797121341ED706BAFFDACA434143FF1D07B0B526B1278312A4C4DFC.
- counter-sale-final-analysis-20260919.log SHA2560C7E229399806E0889C7D7D73D13BFB2E0999F71BACDCD622B4AF617FD56BBDD.

Format/analysis evidence binding is now complete. Other pending boundaries above
remain pending; no build, device or founder acceptance follows from analysis.
