# MoolSocial full-scale production journey map

Last reconciled: 19 July 2026

## Source of truth

- Approved reference: `supermandi-uiux-screenbook/approved-final`
- Approved screen files: 167 (`00` through `166`)
- Flow definitions: 48 total
  - 1 aggregate screenbook sequence
  - 47 operational user-flow definitions
- Production client: `MOOLSOCIAL-PRODUCTION/apps/mobile`
- The HTML screenbook defines product intent, information and reachable
  outcomes. Flutter owns the production interaction design. Reviewer framing,
  phone frames, simulation panels and internal implementation wording must not
  be copied into the user application.

## Non-negotiable implementation rules

1. Implement one end-to-end vertical journey at a time.
2. Every visible tap must complete an action or reveal the next action needed
   to complete the intent.
3. Test every tap, sub-tap and reachable nested branch from a clean state.
4. Cover success, empty, invalid, duplicate, cancelled, loading, retry,
   offline, permission-denied and failure states where the journey permits.
5. A journey is not done at screen rendering. It is done only after:

   `discover → reproduce → evidence → ticket → root cause → fix → build → exact
   replay → affected-journey rerun → full regression`

6. Use customer-facing, action-oriented language. Internal terms such as
   “simulation”, “handoff”, “route”, “workspace state” or “review build” must
   not appear on a customer screen.
7. Use the shared Apple-inspired Mool design system, 44 px minimum targets,
   safe areas, large-text support, reduced-motion support and deterministic
   back navigation.
8. No external transaction is claimed as complete until its production
   provider confirms it. Review adapters remain replaceable behind gateway
   interfaces.

## Ordered vertical slices

| Order | Production slice | Approved flows | Screen coverage | Status |
|---:|---|---|---|---|
| 0 | Install, setup, OTP and Universal entry | `onboarding` | 00–04 | Implemented; two clean regression cycles passed |
| 1 | Household buying, delivery, bill and issue resolution | `buy-delivery`, `buy-issue` | 04, 09–12, 14, 17–22 | Implemented in Flutter; dedicated black-box suite passed |
| 2 | At-shop payment and collection | `buy-counter` | 04, 09–12, 14–16 | Implemented in Flutter with explicit store choice, collection readiness, protected code, handoff and receipt; dedicated black-box suite passed |
| 3 | Transactional and people chat | `chat` | 04, 23–25 | Implemented in Flutter; inbox, people/business/order/support threads, attachments, reply/reaction, failed-send replay, contextual actions and protected return routes passed dedicated and full-app regression |
| 4 | Food delivery, table booking and tiffin | `eat-order`, `eat-table`, `eat-tiffin` | 04, 26–29 | Pending |
| 5 | Ride booking and completion | `ride` | 04, 30–35 | Pending |
| 6 | Doctor, salon and local task booking | `doctor-booking`, `doctor-invite`, `salon`, `get-it-done` | 03–04, 36–56 | Pending |
| 7 | Recharge, bills, scan, request, refund and reversal | `pay-recharge`, `pay-bills`, `pay-scan`, `pay-request`, `pay-refund`, `pay-failure` | 04, 57–66 | Pending |
| 8 | Work identity and retailer onboarding | `earn-workspace`, `retailer-onboarding` | 04, 67–74 | Pending |
| 9 | Retailer orders, POS, procurement, books, services, growth and controls | all `retailer-*` operational flows | 13, 74–106 | Pending |
| 10 | Manufacturer sales, procurement, growth and control | all `manufacturer-*` flows | 107–115 | Pending |
| 11 | Captain ride and earnings | `captain-workspace` | 116–123 | Pending |
| 12 | Creator studio, campaigns, commerce share, membership, licensing and YouTube Connect | all `creator-*` flows plus screen 166 | 05–07, 09, 12, 14, 17–18, 99–100, 113, 124–137, 152, 154, 156, 166 | Pending |
| 13 | Freelancer operations and service-provider workspace | `earn-operations`, `provider-workspace` | 133–146 | Pending |
| 14 | Superadmin operations and dynamic user-type offerings | `admin-operations` | 147–156, 163–164 | Pending |
| 15 | Shared account, security, workspace and notification controls | `shared-controls` | 157–162, 165 | Pending |

## Operational flow register

### Consumer

- `onboarding`: 00 → 01 → 02 → 03 → 04
- `social`: 04 → 05 → 06 → 07 → 08
- `buy-counter`: 04 → 09 → 10 → 11 → 12 → 14 → 15 → 16
- `buy-delivery`: 04 → 09 → 10 → 11 → 12 → 14 → 17 → 18
- `buy-issue`: 18 → 19 → 20 → 21 → 22
- `chat`: 04 → 23 → 24 → 23 → 25
- `eat-order`: 04 → 26 → 27
- `eat-table`: 04 → 26 → 28
- `eat-tiffin`: 04 → 26 → 29
- `ride`: 04 → 30 → 31 → 32 → 33 → 34 → 35
- `doctor-booking`: 04 → 36 → 37 → 38
- `doctor-invite`: 39 → 40 → 03 → 41
- `salon`: 04 → 36 → 42 → 43 → 44 → 45 → 46 → 47
- `get-it-done`: 04 → 36 → 48 → 49 → 50 → 51 → 52 → 53 → 54 → 55 → 56
- `pay-recharge`: 04 → 57 → 58 → 63 → 64
- `pay-bills`: 04 → 57 → 59 → 63 → 64
- `pay-scan`: 04 → 57 → 60 → 63 → 64
- `pay-request`: 04 → 57 → 61 → 62 → 63 → 64
- `pay-refund`: 04 → 57 → 61 → 62 → 63 → 65
- `pay-failure`: 04 → 57 → 61 → 62 → 63 → 66

### Workspaces and operations

- `earn-workspace`: 04 → 67 → 68 → 69 → 70 → 71 → 72 → 73
- `retailer-onboarding`: 70 → 71 → 72 → 73 → 74
- `retailer-orders`: 13 → 74 → 75 → 76 → 77
- `retailer-pos`: 74 → 78 → 79 → 78 → 80 → 90
- `retailer-wholesale`: 74 → 81 → 82 → 83 → 84 → 85 → 86 → 87 → 88 → 89 → 92
- `retailer-books`: 92 → 90 → 92 → 87 → 92 → 91 → 92 → 106
- `retailer-services`: 74 → 93 → 94 → 95 → 96
- `retailer-growth`: 74 → 97 → 98 → 97 → 74 → 99 → 100
- `retailer-controls`: 74 → 101 → 74 → 102 → 74 → 103 → 74 → 104 → 74 → 105 → 74 → 106
- `manufacturer-sales`: 107 → 109 → 107 → 110 → 112
- `manufacturer-procurement`: 107 → 111 → 108
- `manufacturer-growth`: 107 → 113 → 107 → 115
- `manufacturer-control`: 107 → 114 → 107 → 108
- `captain-workspace`: 116 → 117 → 118 → 119 → 120 → 121 → 116 → 122 → 116 → 123
- `creator-workspace`: 124 → 125 → 124 → 126 → 127 → 124 → 128 → 124 → 129 → 124 → 130 → 124 → 131 → 124 → 132
- `creator-funded-campaign`: 100 → 152 → 129 → 125 → 05 → 127 → 154 → 130
- `creator-commerce-share`: 99 → 129 → 125 → 05 → 09 → 12 → 14 → 17 → 18 → 127 → 154 → 130
- `creator-membership`: 132 → 07 → 62 → 63 → 130
- `creator-content-pool`: 06 → 127 → 154 → 130
- `creator-local-production`: 100 → 129 → 125 → 152 → 154 → 130
- `creator-onboarding`: 152 → 133 → 134 → 135 → 136 → 137 → 130
- `creator-live-event`: 113 → 156 → 129 → 125 → 07 → 62 → 63 → 127 → 130
- `creator-licence`: 99 → 131 → 154 → 130
- `earn-operations`: 133 → 134 → 135 → 136 → 137 → 138
- `provider-workspace`: 139 → 140 → 139 → 141 → 139 → 142 → 143 → 144 → 139 → 145 → 139 → 146
- `admin-operations`: 147 → 148 → 149 → 150 → 151 → 152 → 153 → 154 → 155 → 156 → 163 → 164
- `shared-controls`: 162 → 157 → 162 → 158 → 162 → 159 → 162 → 160 → 162 → 161 → 162 → 165

## Buy implementation decisions now locked

- Consumer catalogue shows household quantities only.
- Wholesale MOQ, business case prices, demand aggregation and campaigns do
  not appear in the consumer product grid.
- Home delivery is the default for a consumer shopping from home.
- Store collection becomes active only after the customer explicitly chooses
  a store.
- Duplicate adds increment one basket line instead of creating duplicate rows.
- Product, seller, quantity, price, delivery promise and refund rule are
  visible before checkout.
- Payment failure creates no order and states that no money was deducted.
- Retry uses the same basket and creates one order.
- Delivery completion exposes bill, proof, ratings, repeat purchase and order
  problem resolution.

## Chat implementation decisions now locked

- Chat has one production inbox for people, businesses, linked orders and
  support cases.
- Opening Chat from another journey preserves that exact return screen.
- People threads expose chat, shared media, household basket, polls and member
  invitations.
- Business threads expose chat, catalogue, quote, linked orders and confirmed
  payment entry.
- Order and support threads expose the linked details and chronological
  updates.
- Message attachments, replies and reactions complete visibly. An empty send
  is rejected with a customer-facing correction.
- A failed send remains visible with Retry. Replaying the original failed tap
  sequence replaces it with one delivered message; it does not duplicate it.
- Calls, video calls and potentially sensitive conversation actions require an
  explicit confirmation or show their completed state.

## Release boundary

“Full prototype implemented” and “production live” are different gates. Full
Flutter intent completion can continue against deterministic gateway
interfaces. Public production launch additionally requires live cloud billing,
Firebase production configuration, payment-provider credentials, release
signing, iOS signing/build infrastructure, privacy/legal approval and real
provider sandbox certification.
