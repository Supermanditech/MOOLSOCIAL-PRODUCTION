# C25F Screen04 world projection drift rejection

- Date: 2026-08-09
- Status: registered before runtime correction

The migrated Fix1 contract exposed a real protected Social compatibility defect: `screen04Worlds` still presented Buy/Eat/Ride/Book and the predecessor action placement (Medicine under Buy, no Bus under Ride, no Medicine under Book). Its contextual eyebrow copy also retained Buy/Eat/Ride/Book.

C25 requires every live projection owner to use Shop/Food/Travel/Care and the exact 18-action placement. The correction changes this existing compatibility catalogue and route copy only, adds Bus to the existing Travel projection using `/app/book/bus`, and reuses the existing Medicine content/Buy route under Care. No Social media/feed/create/provider or backend behavior changes.
