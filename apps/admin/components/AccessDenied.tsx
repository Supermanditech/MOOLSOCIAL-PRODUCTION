export function AccessDenied({ reason }: { reason: string }) {
  return (
    <main className="access-page">
      <section className="access-card">
        <div className="brand-mark" aria-hidden="true">
          M
        </div>
        <p className="eyebrow">MOOLSOCIAL SUPERADMIN</p>
        <h1>Protected operations access</h1>
        <p>{reason}</p>
        <p className="privacy-note">
          Public accounts, URL parameters and client-side flags cannot grant
          administrative access.
        </p>
      </section>
    </main>
  );
}
