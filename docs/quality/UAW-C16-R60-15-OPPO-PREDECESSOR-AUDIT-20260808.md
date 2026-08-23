# C16 r60.15 OPPO predecessor audit

## Authority and immutable predecessor

- Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-PROFESSIONAL-DESIGN-SYSTEM-FIX1-C16`.
- Device: physical OPPO CPH2375, serial `2b3e0f71`, 720x1612, density 320,
  font scale 1.0.
- Installed predecessor: `com.moolsocial.app` `1.0.0-r60.15`, version code
  `2026080815`.
- Installed base APK SHA-256:
  `94443C63382205E5E47DC7BBA2D23D98C579B5AADB5C34ADBC443448E1EB0968`.
- Identity result: exact match to the founder-rejected C15 candidate. No build,
  install, uninstall, data clear, downgrade or protected-state mutation occurred.
- Capture root:
  `artifacts/quality/uaw-personal-mvp-global-subaction-professional-design-system-fix1-c16-predecessor-audit-20260808-01`.

The full audit and selected-state matrix completed before a C16 visual design
was selected or production Flutter source was changed.

## Selected-state screenshot matrix

Every admitted PNG has a fresh paired UIAutomator XML dump proving the expected
family and selected sub-action. All 17 PNG hashes are unique.

| Family | Selected state | PNG | SHA-256 |
|---|---|---|---|
| Book | Doctor | `01-book-doctor.png` | `9AB9413FF1EB6629C553D782677C36F1D732AB82D73CB5BB728A75F9538817CE` |
| Book | Salon | `02-book-salon.png` | `BDE2786D5063C23DBE8CE77E4F0C974986ABA6FFA81D0F6A4ADCD81ABC7D6FF7` |
| Work | Earn Today | `03-work-earn-today.png` | `75A2F2510DE1758696845A0896AC5B7123CBF634D26E3DD0C9B4C67A37AA603C` |
| Work | Workspace | `04-work-workspace.png` | `5E32BB57B1246013419C8BD3E626CB4EFBCC7F04EF222F4D328E43489B4017EE` |
| Ride | Bike | `05-ride-bike.png` | `DE2CCC931A78C5B108DF820D428997FEB82F7CF3CEC2A6B804248FDEDBF80CC7` |
| Ride | Auto | `06-ride-auto.png` | `87B5527B8D02944AAD9E103B223097FCE9A2B9B858552B69F44B388EC090B4DC` |
| Ride | Cab | `07-ride-cab.png` | `83A01E3CE77F89ECDA979FE6B016E435DBCCFF7976E2E674685C90082848803A` |
| Eat | Order Food | `08-eat-order-food.png` | `D6B9BF1BAA3181DF8FDAE562C75217D182AC458ACFF179768FF9235F1EDC9769` |
| Eat | Book Table | `09-eat-book-table.png` | `28BEB930C7F0CDE62A506F7433D4A3247A6ED796D69C057A4FCA78E43D70DFD0` |
| Social | Shorts | `12-social-shorts.png` | `F697BF5561CB9F4E9335A27460784F0CE783B0B620ED89A6E516F329D8B6007C` |
| Social | Videos | `13-social-videos.png` | `ABB75AFE888AB319B70E9071BB7D61B838EDDF27941936E368932B9DA901E976` |
| Social | Feed | `14-social-feed.png` | `736923FFADD8632240C77FF41A412B35F07DDD3E3C02279E25D4C24905B109E7` |
| Social | Create | `15-social-create.png` | `B0DA8B0A565922A6C9A889224A1F5E87BDE65649944234956AB190F2C8517E2E` |
| Buy | Shop | `16-buy-shop.png` | `DA2732AA00E87AECF9311B2323E54048364D5828FA0B20A611DA65C64318700F` |
| Buy | Wholesale | `17-buy-wholesale.png` | `FA3708759127393456885A59657584BBD6007D00618CD56ECE30D96285EC9E54` |
| Buy | Medicine | `18-buy-medicine.png` | `130C19BB5D9DE04690874A5C6268474724AC89F7C81E8F947F1EA7A9A176825E` |
| Buy | Orders | `19-buy-orders.png` | `6D3B45FEC8DC993737D8A1CFAA89BAA2B83C00B672332339902D72594D124A91` |

## Finite-motion frame evidence

The OPPO does not expose `screenrecord`; the rejected MP4 attempt is registered
as `REG-20260808-307`. Motion is therefore proven by individually checksummed
fresh screenshot sequences and final selected-state semantics.

- Left, Ride Cab to Bike:
  `20-ride-left-before.png` `ECE27C82FC88E09B378B4148E24BB1B6242C64C5F6C36E5B155D72F12FC85ACF`;
  `21-ride-left-event.png` `089EB6B6774D8B644547AEDEA086713F075A4A9019B5B5FF14DB5E09E4AEB169`;
  `22-ride-left-mid.png` `ADFEA00C2D9B522BA875B6C9CB7168E673CA419DDCC38277B68037E629FC926E`;
  `23-ride-left-settled.png` `E14A0D79751975315D14610716F84538ABEE9F0EEC9C4FC61A24DA91561B997B`.
- Right, Ride Bike to Cab:
  `24-ride-right-before.png` `84B29AB5C2A7ABAD183335EB4402E9F67CB8242E6217780909053DCC39F70503`;
  `25-ride-right-event.png` `88E01CBF023C176F8C5990CC89A90121F1AEE1070047C48D1BD1DB47199BD881`;
  `26-ride-right-mid.png` `DC53EF23005F0FAC6DF723E1044C288DE8821ACDB5D479294BC3360F49975BAD`;
  `27-ride-right-settled.png` `9570B96482CAAB54C7BBAD63CB17105887FD92CBF8715D8B4F6A73A95A3C9E60`.
- Cross-route, Ride Cab to Eat Order Food:
  `28-cross-route-before-ride.png` `3F560B9B034B98795BC9E6B1917C43372734CB5BAEC6CCCEF158193CB83D00B8`;
  `29-cross-route-event-eat.png` `A9AAD1586BDEAAF19365083CFBE83D2C4AD58A2BBC5148C95B5AD3C1ACF1AF0F`;
  `30-cross-route-mid-eat.png` `BDADAC44981E25CBC79ED05E5906F29E0ED19F02EEAB88B635A848954FCF8A99`;
  `31-cross-route-settled-eat.png` `F2B466086F7410C670B36C3307203AD7870AFFD5FF5AE089321BA4DA4A3D4901`.

The frames show finite directional movement and the selected-family wave while
the approved full global rail remains visually present. They also show why
motion alone did not make C15 professionally uniform.

## Observed predecessor findings

1. Social uses its bespoke `_TrackingRailRibbon` / `_RailAction` renderer,
   provider artwork, variable label sizes and four equal full-row cells.
2. Buy uses the bespoke `_BuyDestinationTabs` horizontal lane with four
   edge-to-edge 180px cells, independent type/icon/spacing tokens and overflow
   cues. It reads as the rejected strip.
3. Eat, Book and Work use two half-screen cells; Ride uses three one-third-screen
   cells. The low-count families are visibly overstretched instead of forming a
   compact family cluster.
4. Selected state, icon scale, label scale, internal spacing and attribution
   behavior differ among Social, Buy and the four shared-rail families.
5. The local rail plus global rail consumes a large persistent bottom stack.
   The admitted states keep their primary hit targets above it, but the visual
   displacement and the risk of future content occlusion must remain explicit
   regression gates.
6. The founder-approved global rail geometry, order, position and meaning are
   consistent and must be preserved. C16 changes only the shared sub-action
   design owner and destination-content transition contract.
7. No missing customer outcome or duplicate requires a new action. Counts stay
   Social 4, Buy 4, Eat 2, Ride 3, Book 2 and Work 2; filler symmetry is
   forbidden.

## Rejected and diagnostic artifacts

- `11-social-shorts.png` / XML remained Eat / Book Table and are preserved only
  as rejected evidence under `REG-20260808-302`; they are not in the matrix.
- `ime-dismiss-check.png` proves the Create keyboard was visibly dismissed
  before rail navigation; ColorOS's stale secondary flag is registered under
  `REG-20260808-305`.
- `motion-failure-state.xml` records the failed unavailable-recorder attempt's
  true Ride / Cab end state and is not motion proof.

## Audit decision

The mandatory predecessor gate passes. C16A may now select one existing shared
native-Flutter owner and token system. The read-only HTML screenbook remains
unchanged and is not copied into production.
