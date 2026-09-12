# Buy V2 r65.1 motion disposition

- Applied: finite order-success confirmation, segmented-control state transitions, product/store/card entrance, compact Cart value transitions and payment/status transitions.
- Reused: established Buy finite event-driven motion and static reduced-motion fallbacks.
- Dependency held: shared Chat motion and global shared-shell motion remain with their existing owners.
- Inapplicable: perpetual decorative loops, non-functional video effects and motion that changes business state.

All motion preserves hit ownership and semantics and resolves to a static state when reduced motion is enabled.
