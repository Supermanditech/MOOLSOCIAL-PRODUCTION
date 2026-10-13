# Counter Sale r66.35 local qualification

Approved v26 implementation is sealed at 8bfda8f862837bdc43910476a841befb750b6114,
remote-exact on its feature branch before candidate admission edits. UI hashes:
dashboard A55AFCC96E00C5FC97CC493EF7168BFEEA1BBD82EAF7E592FAAAEFD9001DE7A2;
layout test 1F96362C53F728913DEBDB4DF6FC403D1B66C91CE189F18C2942A4AC9D8A6FC7.

Two complete serial cycles retain all previous 44 test owners and add invoice PDF:
2,789 passed / 87 skipped / zero failed each; 21m18s and 22m52s. Source plus all
45 test owners were unchanged between cycles. Existing protected-reference
exclusion is unchanged. Skips are not accepted cases.

A read-only formatting check found one assertion indented two spaces too little.
The original failure log is retained. Formatter output was byte-compared against
that single indentation correction; no runtime source changed. All eight owners
then passed read-only format, and the whole formatted atomic suite passed
337 / 4 skipped. Source-manifest comparison proves this one test-only change.
Full Dart analysis, UI locks, copy, Android resources and commit coverage pass.

Exact prospective four review flags plus the test-only EXPECT_REVIEW_PDF oracle:
PDF selection 1 passed; PDF generation 1; Work isolation 6; Chat isolation 4;
review Store recovery 5 / 1 mode skip. Production/disabled-mode isolation is
covered in the full cycles. These use mocked secure storage, not physical
restart, encryption, production inventory or live-payment proof.

Evidence directory outside Git:
C:/Users/jisal/Documents/Codex/2026-09-19/restock-testing-in-store/outputs.
Immutable log names and SHA256:

- counter-sale-approved-v26-full45-cycle-01-27.log: 25BC570A02CC1720AF7709C919FBCBFA1FEF527CA4173A448618250DD0F1AEAD
- counter-sale-approved-v26-full45-cycle-02-27.log: B162FF17E091635A8091AE6105AD182B4AB7CCC0AE8A243AF94547C8CCFA3876
- counter-sale-approved-v26-analysis-27.log: 745F8775F89DA0D6DCC7997A30EEAD07C9D51B450AB198140D2C7DB8F01F72FC
- counter-sale-approved-v26-format-fixed-28.log: E8B4CE9B30736C96F98154C94AE8D0307AAAB5EF0F72A6069957BEAE5FA04FB7
- counter-sale-approved-v26-atomic-formatted-28.log: AE8447F6C79DB18988624546DD9129671CEBC23EEE80F4ABD7FB55EA4E96EEE8
- counter-sale-approved-v26-review-pdf-selection-28.log: 236359F77EAAC9EF79DCA8F9147F284E5D3CA45D82581F048C9CAF2EF7168487
- counter-sale-approved-v26-review-pdf-generation-28.log: AD5868ACAA5403DAE882087B2574A0D704A8B51CADE1D58C8D4F73C7B74700C5
- counter-sale-approved-v26-review-work-isolation-28.log: 6BC0EBC0324C3D96E7E77E75F2A228B44D9FC0845F6484D3D1BAD8F7C86145A0
- counter-sale-approved-v26-review-chat-isolation-28.log: 855C62B46EA8D007BAEB046A7DC32F0D106CC1227218A1447EF2D14DC4861FB2
- counter-sale-approved-v26-review-relaunch-28.log: 5033A832C4BB450A61EDD458D59613E887EC691029378437744C3461F91F2848
- counter-sale-approved-v26-ui-locks-27.log: 3E4264965F00119D5F60E86C03C1262B7C17F6B683F112D3DC1C81A8C21BAC68
- counter-sale-approved-v26-copy-27.log: B638156BB33D2E2ABB62FC5DCEF7BB7F96C8E508E7597024C70B1AE8924D717F
- counter-sale-approved-v26-resource-27.log: 79FE075CF66B1D7C616891188A8D096B4F6EF0F3AB62AF34719A448CAC6CB4BF
- counter-sale-approved-v26-coverage-27.log: 1C2ADF02E2C83DEE9BDCA31C3C0BBDEB5DCD89CEF4386B61FCB0941B81CE19F1
- counter-sale-approved-v26-precommit-final-29.log: 0C14605212C1DBEC8D9A90AB790D4447BFE1B8F2279C6D03D8FB087B63235AC5

Founder-approved local screenbook: counter-sale-brand-full-journey-v26.md in
that directory. No local capture is represented as a new OPPO screenshot.
