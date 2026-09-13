# UAW-CURSOR-UI-SHOP-LANDING-V2-CHILD5-ORDERS-OWNER-20260828

State: `bounded_orders_visible_owner_oracle_correction`

- Parent: `UAW-CURSOR-UI-SHOP-LANDING-V2-20260828`.
- Work ID: `shop-v2-child5-orders-owner-20260828`.
- Task: `/root/cursor_shop_v2_child5_orders_owner_20260828`.
- Branch: `work/cursor-ui/shop-v2-child5-orders-owner-20260828`.
- Baseline: `58a04f2329b658c7b7296ad7055fda43be2a1022`.

The Shop profile CTA correctly moved the session to Orders/catalogue, but the
test guessed absent key `buy-orders`. This child resolves the exact existing
Orders view key from the claimed runtime owner and changes only that assertion.
