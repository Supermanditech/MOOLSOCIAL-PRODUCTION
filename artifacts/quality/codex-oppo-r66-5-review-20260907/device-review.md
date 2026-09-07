# r66.5 OPPO review

## Current checkpoint: installed, limited device review

On 7 September 2026, OPPO CPH2375/2b3e0f71 was connected. Update-install with adb install -r succeeded from r66.4; no clear-data, uninstall, production package or Redmi action occurred. Installed version1.0.0-r66.5-runtime/code2026090604 and device base-APK SHA-25669EEC3287857A634BFDD71E7327BCFAD347DC60526165657499F40E9CBA807AE equal the sealed candidate. The APK and its source/provenance were not rebuilt or changed. MainActivity cold launch returned Status ok/TotalTime7198ms.

- Actually observed: Shop startup, Mool menu, Work/Earn entry, Workspace selector and Grocery/Kirana same-page introduction. PNG01,04,05,06 were directly visually inspected; XML02/03/07 was inspected. Search hint now displays the complete word Search, resolving the earlier r66.4 ellipsis observation in this captured layout. Selector/preview and Choose this Workspace are above Android navigation in the captured viewport.
- OPPO-R66.5-REVIEW-ENTRY-01: Store dashboard/device review remains blocked by review-state provisioning, not by APK installation. ReviewWorkGateway.loadFeed returns an empty list after restart and device review defaults to pending. The prior r66.4 checkpoint also ended at the selector; do not infer lost approved business data. Provide an explicitly isolated approved review fixture for native Store review or an authenticated approved-workspace response; never alter production approval rules or describe a fixture as live approval/payment/collection authority. No review-state injection was performed.
- Existing OPPO-R66.4-OBS-02 remains open, not duplicated: Earn Today still shows the review Quick Delivery Biker HIRING NOW with05Sep2026 deadline on07Sep2026. XML03 is identical to the prior retained sample. This is stale fixture content, not proof of real hiring.
- During the selector observation, a Quick Delivery Biker application banner appeared between captures04/05. Its origin was not established; do not label this a deterministic card-tap defect. Later the foreground guard stopped the attempted system Back before input. Capture07 was made only after a new foreground check again confirmed runtime; its filename does not mean Back executed. Automated interaction stopped pending exclusive screen review. No unrelated app screenshot was taken.
- Native dashboard/first-tap operations, Back, keyboard, large text, real picker, order timers, collection and end-to-end journeys remain pending. No blanket device pass, production backend acceptance or founder approval is claimed.

### Immutable local capture inventory

Directory: artifacts/device/codex-oppo-r66-5-review-20260907. Generated PNG/XML/install log are preserved, Git-ignored and hash-bound here. UI/source/test blobs remain unchanged.

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| oppo-install-attempt1.log | 38 | C4AA470ACAFCF8576C15B0F0B5AE7E852D1EC5413372D0E6A9272E788E1306D3 |
| r665-oppo-01-startup.png | 415879 | B394F7D187E77764268753246ABE1F19ABAD1CF31947FB6FAA999EEB55776774 |
| r665-oppo-01-startup.xml | 24491 | 6400967F59679BBB5287E435EA70E5B9E43E28CE317C88AF5C232E95134B957F |
| r665-oppo-02-mool.png | 362223 | EA3D25F2B6960D8601308511F912F292F72F555C8C51FD3487C28524B8F783BA |
| r665-oppo-02-mool.xml | 28181 | 7D0123414D61A8640FAD4269398B6551969449E9FE0B52DB956088C1B09857A0 |
| r665-oppo-03-work.png | 215453 | 04B0D443780D3AEFF66F5A8EB7C0EB147C7EFFC370F3CC6B160C6ABC68177AA5 |
| r665-oppo-03-work.xml | 12056 | 130F16C31085DA72D07B833642C48E1992B632813D32BB064B4B4080A1BE96F7 |
| r665-oppo-04-store.png | 178073 | 4C8C58677C6E930E35EB4DA90AD6B4C05D31D3A346181D65CA3ECB388DE2013E |
| r665-oppo-04-store.xml | 10399 | 04465DFE282146F400DE671AD1CA55C443E2B424EC22A219289D74497FA5AC41 |
| r665-oppo-05-retailer-preview.png | 169720 | DE2D9C9AFE8446C49BB6B3CFF835B658F015EAB801206DB605D3CEFE36583D9F |
| r665-oppo-05-retailer-preview.xml | 10332 | 47092546109426291297A8A01FE85EAFADE85931C2EBFB13DCD30114CF274DAB |
| r665-oppo-06-retailer-expanded.png | 142914 | AE981363AE1E0FD72F5F2F3CD580EBD80E8D714AE6B481F10714BEBED7709696 |
| r665-oppo-06-retailer-expanded.xml | 12951 | 4C0DEBACBD49106C91EF48F6B96FE230F4CC91F39FB34F14BC40A04F3AFBB630 |
| r665-oppo-07-back.png | 143030 | 16DCF3FEC83054CFB5935690FF8C78805CFA5356E01E1EEA1B2D209406F62195 |
| r665-oppo-07-back.xml | 12951 | 4C0DEBACBD49106C91EF48F6B96FE230F4CC91F39FB34F14BC40A04F3AFBB630 |

## Previous connection-only checkpoint (superseded by the current checkpoint)


APK built and independently verified: source91d9a9b8a321946bc26a1c4645b22784ab43f2e3; runtime package1.0.0-r66.5-runtime/code2026090604;209715721bytes;SHA-25669EEC3287857A634BFDD71E7327BCFAD347DC60526165657499F40E9CBA807AE.

Device phase is blocked by connection only. The existing device memory gate passed. ADB reported device2b3e0f71 not found, and adb devices -l reported no attached devices. Founder was asked to reconnect/unlock OPPO and accept USB debugging if prompted. No install, device data clearing, screenshot, tap, Android permission change or device journey was performed in this round. Redmi and other packages remain untouched.

Resume: verify OPPO CPH2375/2b3e0f71, run the current required device checks, update-install only this exact APK with -r, then read installed package/version/base-APK checksum. Launch the isolated runtime package, confirm its foreground identity before captures, and replay the Workspace/Store/dashboard first-tap corrections one screen at a time. Record actual device defects and founder feedback without counting local fixtures as device/backend qualification. Do not send WhatsApp messages or submit real payments.

Local qualification is complete as recorded in local-validation.md: two1315-pass connected cycles,89 native cases and156 captures. Native stills cannot close OPPO smoothness, keyboard, real picker or founder appearance review. Backend and consumer collection integration remain explicitly pending in ticket-and-screen-coverage.md. No new OPPO defect is invented from the missing USB connection.
