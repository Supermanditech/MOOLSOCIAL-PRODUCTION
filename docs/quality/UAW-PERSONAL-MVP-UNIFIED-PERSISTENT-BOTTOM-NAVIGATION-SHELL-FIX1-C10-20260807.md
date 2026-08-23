# UAW Personal MVP unified persistent bottom navigation shell Fix1 C10

State: founder approved; OPPO audit complete; implementation active.

## Founder journey and reproduced evidence

The founder opened the installed r60.9 app, observed a Work/Workspace arrival,
selected Mool, selected Social, and selected Mool again. The latest three OPPO
screenshots were pulled read-only from the founder-authorized screenshot folder
and preserved under the C10 artifact directory.

The frames prove three competing bottom-navigation owners:

1. Work renders `Mool / Earn Today / Workspace / Chat` and a header Back arrow.
2. Mool Home renders the six main actions between Mool and Chat.
3. Social renders `Mool / Shorts / Videos / Feed / Create / Chat`.

Although Social to Mool now reaches the new Home, switching destinations changes
the geometry, labels and meaning of the global control. The person cannot form a
stable location model and exact return feels uncertain.

## Codex disposition

This is an MVP-blocking global navigation defect. A production app cannot use
the same bottom position for three incompatible information architectures.
C10 owns one global contract:

- Mool and Chat are stable edges.
- Social, Buy, Eat, Ride, Book and Work are the stable main destinations.
- The current destination is visibly selected and its retap is a disabled no-op.
- Shorts, Videos, Feed, Create, Earn Today, Workspace and equivalent destination
  subactions are local content controls; they never replace global navigation.
- A top-level destination has no header Back arrow. System Back first closes
  content depth, then restores the exact prior destination state and history.
- Main-destination changes use finite directional motion and honor reduced
  motion.
- A fresh authenticated launch without a deep link opens Social rather than a
  stale Work/Workspace route.

## Runtime cleanliness

The implementation will reuse the existing production design primitives and
route/session owners. Replaced rail/toggle/modal owners must have no compiled
reachable call site; an old test or retained audit artifact cannot own runtime
behavior. Historical evidence remains preserved under workspace rules.

No APK build or OPPO mutation is authorized by this ticket registration. The
installed r60.9 remains rejected evidence until host qualification passes and a
separate machine-gated successor build is authorized.

## C10C host qualification result

C10C is host implemented and fully qualified for the Buy-owned scope. BuyV2 and
the reachable grocery/order scaffold now use the shared global bottom owner;
Shop, Wholesale, Medicine, Orders and Help are destination-local controls; top
Back and the retired `buy-dock-*` runtime owner are absent. Exact product,
Cart, Checkout, order and tracking depth is preserved.

Evidence passed on 07 August 2026:

- full Buy screen: 69/69;
- combined design, Buy, scoped-golden and C10C contract: 82/82;
- broader route, motion, contextual header, grocery, shared dock and copy set:
  80/80;
- deterministic real-asset navigation goldens: 5/5 strict comparison;
- Flutter analysis: no issues;
- customer-copy, global contract, C10B, C10C and regression-memory gates: pass.

This is host qualification only. No successor APK has been built or installed,
so the connected OPPO continues to show the rejected r60.9 behavior.

## Latest founder OPPO confirmation

The founder reconfirmed the same C10 device defect from three real-user frames:
a fresh open landed on Work/Workspace instead of Social; Mool and Social were
reachable; Social to Mool returned to the new flow; but each top-level change
still looked like a new page because rail geometry and meaning changed. The
founder also reconfirmed that top-level header Back is unnecessary and retired
navigation source must not remain compiled and reachable.

These findings remain owned by C10A for cold launch and C10E for global motion,
runtime containment, machine-gated build/install and OPPO screenshot replay.

## C10D host qualification result

C10D is host implemented and fully qualified for Chat. Chat inbox is now a
top-level shared-dock destination with Chat selected and no header Back; thread
depth retains a content Back control; global switches and system Back restore
the exact live inbox/thread owner. Inbox query/filter, thread draft, focus and
IME state survive the tested round trips. The retired destination-local Mool
launchers have no reachable production call site.

Evidence passed on 07 August 2026:

- dedicated C10D contract: 3/3;
- existing Chat flow: 6/6;
- prior affected navigation family: 46/46;
- complete affected navigation family: 159/159;
- Flutter analysis: no issues;
- global, C10B, C10C, C10D, customer-copy and regression-memory gates: pass;
- retired Chat Mool keys and positive retired Buy top-Back usage: absent.

This is host qualification only. No successor APK has been built or installed,
so the connected OPPO continues to show rejected r60.9 behavior. C10E now owns
finite directional motion, reduced-motion behavior, complete retired-source
containment and the separately machine-gated successor OPPO replay.
