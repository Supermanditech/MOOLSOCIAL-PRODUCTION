# UAW-CURSOR-UI-SHOP-LANDING-V2-CHILD3-ORDER-ORACLE-20260828

State: `bounded_preimplementation_test_oracle_correction`

- Parent: `UAW-CURSOR-UI-SHOP-LANDING-V2-20260828`.
- Work ID: `shop-landing-v2-child3-order-oracle-20260828`.
- Task: `/root/cursor_shop_landing_v2_child3_order_oracle_20260828`.
- Branch: `work/cursor-ui/shop-landing-v2-child3-order-oracle-20260828`.
- Baseline: `8d74dc56d01fba6050b0c04ed75851fdc6191abc`.

Focused analysis rejected the first profile-context test because it asserted a
nonexistent `BuyV2View.orders` enum. `openOrders()` owns the truthful current
Orders view contract. This child replays the same Shop implementation and
asserts the existing session view/visible owner without inventing an enum.

No device, build, backend or shared-profile owner is changed.
