"use client";

import Link from "next/link";
import {
  type FormEvent,
  useMemo,
  useRef,
  useState,
  useTransition,
} from "react";

import {
  adminProfileTargets,
  adminScreens,
} from "@/lib/admin-data";
import type { AdminAccess } from "@/lib/admin-auth";
import {
  emptyOfferingDraft,
  type AdminCase,
  type AdminScreen,
  type OfferingDraft,
  type OfferingKind,
} from "@/lib/admin-types";

type ActionKind = "primary" | "secondary";

type AdminConsoleProps = {
  access: AdminAccess;
  initialScreen: AdminScreen;
  failureMode: boolean;
  commandMode?: string;
};

const offeringKinds: OfferingKind[] = [
  "Product",
  "Service",
  "Business-funded Reel",
  "Guaranteed outcome",
  "Funded work",
  "Required action",
];

const fundedReelDurations = [
  "1 day (24 hours)",
  "2 days (48 hours)",
  "3 days",
  "4 days",
  "5 days",
  "6 days",
  "7 days",
] as const;

const ownerPaths: Record<string, string> = {
  "147-payment-safety": "/admin/finance",
  "147-ride-safety": "/admin/rides",
  "147-order-capacity": "/admin/commerce",
  "164-grocery-planning": "/admin/configuration",
};

function actionReference(
  screen: number,
  item: AdminCase,
  kind: ActionKind,
) {
  return `ADM-${screen}-${item.id}-${kind}`.toUpperCase();
}

export function AdminConsole({
  access,
  initialScreen,
  failureMode,
  commandMode,
}: AdminConsoleProps) {
  const [activeFilter, setActiveFilter] = useState(initialScreen.filters[0]);
  const [search, setSearch] = useState("");
  const [selectedCase, setSelectedCase] = useState<AdminCase | null>(null);
  const [confirmed, setConfirmed] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [outcome, setOutcome] = useState<{
    id: string;
    message: string;
    kind: ActionKind;
  } | null>(null);
  const [completed, setCompleted] = useState<Set<string>>(new Set());
  const [mobileNavOpen, setMobileNavOpen] = useState(false);
  const [composerOpen, setComposerOpen] = useState(false);
  const [isPending, startTransition] = useTransition();
  const attemptedFailures = useRef(new Set<string>());

  const visibleCases = useMemo(() => {
    const query = search.trim().toLowerCase();
    return initialScreen.items.filter((item) => {
      const matchesSearch =
        !query ||
        `${item.title} ${item.kicker} ${item.meta} ${item.status}`
          .toLowerCase()
          .includes(query);
      const matchesFilter =
        activeFilter === initialScreen.filters[0] ||
        item.tags.includes(activeFilter);
      return matchesSearch && matchesFilter;
    });
  }, [activeFilter, initialScreen, search]);

  function openCase(item: AdminCase) {
    setSelectedCase(item);
    setConfirmed(false);
    setError(null);
    setOutcome(null);
  }

  function closeCase() {
    setSelectedCase(null);
    setConfirmed(false);
    setError(null);
    setOutcome(null);
  }

  function executeCaseAction(kind: ActionKind) {
    if (!selectedCase) return;
    const label =
      kind === "primary" ? selectedCase.primary : selectedCase.secondary;
    if (!label) return;

    const id = actionReference(initialScreen.screen, selectedCase, kind);
    if (completed.has(id)) {
      setError(null);
      setOutcome({
        id,
        kind,
        message: "This action is already complete. No duplicate was created.",
      });
      return;
    }
    if (!confirmed) {
      setOutcome(null);
      setError("Confirm the evidence and permitted scope before continuing.");
      return;
    }
    if (commandMode === "offline") {
      setOutcome(null);
      setError(
        "You are offline. Nothing changed. Reconnect and retry this same action.",
      );
      return;
    }
    if (commandMode === "denied") {
      setOutcome(null);
      setError(
        "Your current role cannot complete this action. Nothing changed.",
      );
      return;
    }

    setError(null);
    setOutcome(null);
    startTransition(async () => {
      await new Promise((resolve) => setTimeout(resolve, 180));
      if (failureMode && !attemptedFailures.current.has(id)) {
        attemptedFailures.current.add(id);
        setError(
          "The action could not be completed. Nothing changed. Retry the same action.",
        );
        return;
      }
      setCompleted((current) => new Set(current).add(id));
      setOutcome({
        id,
        kind,
        message:
          kind === "primary"
            ? selectedCase.primaryOutcome
            : selectedCase.secondaryOutcome ??
              "The alternative action completed with its reason recorded.",
      });
    });
  }

  const navClass = mobileNavOpen ? "side-nav side-nav-open" : "side-nav";

  return (
    <div className="admin-shell" data-testid={`admin-screen-${initialScreen.screen}`}>
      <a className="skip-link" href="#admin-main">
        Skip to operations
      </a>
      <aside className={navClass} aria-label="Superadmin areas">
        <div className="brand-row">
          <div className="brand-mark" aria-hidden="true">
            M
          </div>
          <div>
            <strong>MoolSocial</strong>
            <span>Superadmin</span>
          </div>
          <button
            className="icon-button nav-close"
            type="button"
            aria-label="Close navigation"
            onClick={() => setMobileNavOpen(false)}
          >
            ×
          </button>
        </div>
        <nav>
          {adminScreens.map((screen) => (
            <Link
              className={
                screen.screen === initialScreen.screen
                  ? "nav-link nav-link-active"
                  : "nav-link"
              }
              data-testid={`nav-${screen.screen}`}
              href={screen.path}
              key={screen.screen}
              onClick={() => setMobileNavOpen(false)}
            >
              <span>{screen.navLabel}</span>
            </Link>
          ))}
        </nav>
        <div className="nav-privacy">
          <span className="status-dot" aria-hidden="true" />
          <div>
            <strong>
              {access.reviewMode ? "Review environment" : "Protected access"}
            </strong>
            <span>
              {access.reviewMode
                ? "Isolated training data"
                : "Role verification active"}
            </span>
          </div>
        </div>
      </aside>

      <main className="admin-main" id="admin-main">
        <header className="topbar">
          <button
            className="icon-button nav-open"
            type="button"
            aria-label="Open navigation"
            onClick={() => setMobileNavOpen(true)}
          >
            ☰
          </button>
          <div className="topbar-title">
            <span>{initialScreen.role}</span>
          </div>
          <div className="admin-identity">
            <span className="avatar" aria-hidden="true">
              {access.email?.slice(0, 1).toUpperCase()}
            </span>
            <div>
              <strong>{access.role}</strong>
              <span>{access.email}</span>
            </div>
          </div>
        </header>

        {access.reviewMode && (
          <div className="review-banner" role="status">
            Review environment · actions use isolated training data
          </div>
        )}

        <div className="page-content">
          <section className="page-heading">
            <div>
              <p className="eyebrow">ACCOUNTABLE OPERATIONS</p>
              <h1>{initialScreen.title}</h1>
              <p>{initialScreen.subtitle}</p>
            </div>
            {initialScreen.composer && (
              <button
                className="button button-primary composer-button"
                data-testid="offering-create"
                type="button"
                onClick={() => setComposerOpen(true)}
              >
                Create offering
              </button>
            )}
          </section>

          <section className="stat-grid" aria-label="Current measures">
            {initialScreen.stats.map((stat) => (
              <article className="stat-card" key={stat.label}>
                <span>{stat.label}</span>
                <strong>{stat.value}</strong>
                <p>{stat.note}</p>
              </article>
            ))}
          </section>

          <section className="control-panel" aria-label="Queue controls">
            <label className="search-field">
              <span>Search this area</span>
              <input
                data-testid="queue-search"
                type="search"
                value={search}
                onChange={(event) => setSearch(event.target.value)}
                placeholder="Case, user-safe reference or outcome"
              />
            </label>
            <div className="filter-row" aria-label="Queue filters">
              {initialScreen.filters.map((filter) => (
                <button
                  className={
                    filter === activeFilter
                      ? "filter-chip filter-chip-active"
                      : "filter-chip"
                  }
                  data-testid={`filter-${filter.toLowerCase().replaceAll(" ", "-")}`}
                  key={filter}
                  type="button"
                  onClick={() => setActiveFilter(filter)}
                >
                  {filter}
                </button>
              ))}
            </div>
          </section>

          <section className="queue-heading">
            <div>
              <h2>{initialScreen.queueTitle}</h2>
              <p>{initialScreen.queueNote}</p>
            </div>
            <span>{visibleCases.length} visible</span>
          </section>

          {visibleCases.length ? (
            <section className="case-list" aria-label={initialScreen.queueTitle}>
              {visibleCases.map((item) => (
                <CaseCard
                  item={item}
                  key={item.id}
                  onOpen={() => openCase(item)}
                />
              ))}
            </section>
          ) : (
            <section className="empty-state" data-testid="queue-empty">
              <span aria-hidden="true">⌕</span>
              <h2>No matching action</h2>
              <p>Change the search or return to the first queue filter.</p>
              <button
                className="button button-secondary"
                type="button"
                onClick={() => {
                  setSearch("");
                  setActiveFilter(initialScreen.filters[0]);
                }}
              >
                Clear search and filters
              </button>
            </section>
          )}

          <aside className="governance-note">
            <strong>Operating boundary</strong>
            <span>{initialScreen.note}</span>
          </aside>
        </div>
      </main>

      {selectedCase && (
        <CaseDialog
          caseItem={selectedCase}
          screen={initialScreen.screen}
          confirmed={confirmed}
          completed={completed}
          error={error}
          isPending={isPending}
          outcome={outcome}
          onClose={closeCase}
          onConfirm={setConfirmed}
          onExecute={executeCaseAction}
        />
      )}

      {composerOpen && (
        <OfferingComposer
          failureMode={failureMode}
          commandMode={commandMode}
          onClose={() => setComposerOpen(false)}
        />
      )}
    </div>
  );
}

function CaseCard({
  item,
  onOpen,
}: {
  item: AdminCase;
  onOpen: () => void;
}) {
  return (
    <article className={`case-card tone-${item.tone}`}>
      <div className="case-card-main">
        <div className="case-kicker">
          <span>{item.kicker}</span>
          <span className={`status status-${item.tone}`}>{item.status}</span>
        </div>
        <h3>{item.title}</h3>
        <p>{item.meta}</p>
        <div className="facts facts-compact">
          {item.facts.map((itemFact) => (
            <div key={itemFact.label}>
              <span>{itemFact.label}</span>
              <strong>{itemFact.value}</strong>
            </div>
          ))}
        </div>
      </div>
      <div className="case-card-action">
        <span className="time-pill">{item.time}</span>
        <button
          className="button button-primary"
          data-testid={`case-open-${item.id}`}
          type="button"
          onClick={onOpen}
        >
          Review action
        </button>
      </div>
    </article>
  );
}

function CaseDialog({
  caseItem,
  screen,
  confirmed,
  completed,
  error,
  isPending,
  outcome,
  onClose,
  onConfirm,
  onExecute,
}: {
  caseItem: AdminCase;
  screen: number;
  confirmed: boolean;
  completed: Set<string>;
  error: string | null;
  isPending: boolean;
  outcome: { id: string; message: string; kind: ActionKind } | null;
  onClose: () => void;
  onConfirm: (value: boolean) => void;
  onExecute: (kind: ActionKind) => void;
}) {
  const primaryId = actionReference(screen, caseItem, "primary");
  const secondaryId = actionReference(screen, caseItem, "secondary");
  const ownerPath = ownerPaths[`${screen}-${caseItem.id}`];

  return (
    <div className="dialog-backdrop" role="presentation">
      <section
        aria-labelledby="case-dialog-title"
        aria-modal="true"
        className="dialog"
        data-testid="case-dialog"
        role="dialog"
      >
        <header className="dialog-header">
          <div>
            <p className="eyebrow">{caseItem.kicker}</p>
            <h2 id="case-dialog-title">{caseItem.title}</h2>
            <p>{caseItem.meta}</p>
          </div>
          <button
            aria-label="Close action"
            className="icon-button"
            data-testid="case-close"
            type="button"
            onClick={onClose}
          >
            ×
          </button>
        </header>
        <div className="dialog-scroll">
          <div className="facts">
            {caseItem.facts.map((itemFact) => (
              <div key={itemFact.label}>
                <span>{itemFact.label}</span>
                <strong>{itemFact.value}</strong>
              </div>
            ))}
          </div>
          <p className="case-detail">{caseItem.detail}</p>
          <ol className="step-list">
            {caseItem.steps.map((itemStep, index) => (
              <li
                className={
                  index < caseItem.currentStep
                    ? "step-complete"
                    : index === caseItem.currentStep
                      ? "step-current"
                      : ""
                }
                key={`${itemStep.label}-${index}`}
              >
                <span>{index < caseItem.currentStep ? "✓" : index + 1}</span>
                <div>
                  <strong>{itemStep.label}</strong>
                  <p>{itemStep.outcome}</p>
                </div>
              </li>
            ))}
          </ol>

          <label className="confirmation">
            <input
              checked={confirmed}
              data-testid="case-confirm"
              type="checkbox"
              onChange={(event) => onConfirm(event.target.checked)}
            />
            <span>{caseItem.confirmation}</span>
          </label>

          {error && (
            <div className="message message-error" data-testid="case-error" role="alert">
              {error}
            </div>
          )}
          {outcome && (
            <div
              className="message message-success"
              data-testid="case-outcome"
              role="status"
            >
              <strong>{outcome.message}</strong>
              <span>Reference {outcome.id}</span>
              {ownerPath && outcome.kind === "primary" && (
                <Link className="inline-link" href={ownerPath}>
                  Continue to owner area
                </Link>
              )}
            </div>
          )}
        </div>
        <footer className="dialog-footer">
          <button
            className="button button-quiet"
            type="button"
            onClick={onClose}
          >
            Cancel
          </button>
          {caseItem.secondary && (
            <button
              className="button button-secondary"
              data-testid="case-secondary"
              disabled={isPending}
              type="button"
              onClick={() => onExecute("secondary")}
            >
              {completed.has(secondaryId)
                ? "Alternative complete"
                : caseItem.secondary}
            </button>
          )}
          <button
            className="button button-primary"
            data-testid="case-primary"
            disabled={isPending}
            type="button"
            onClick={() => onExecute("primary")}
          >
            {isPending
              ? "Completing…"
              : completed.has(primaryId)
                ? "Action complete"
                : caseItem.primary}
          </button>
        </footer>
      </section>
    </div>
  );
}

function OfferingComposer({
  failureMode,
  commandMode,
  onClose,
}: {
  failureMode: boolean;
  commandMode?: string;
  onClose: () => void;
}) {
  const [draft, setDraft] = useState<OfferingDraft>(emptyOfferingDraft);
  const [reviewing, setReviewing] = useState(false);
  const [confirmed, setConfirmed] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const failedOnce = useRef(false);

  function update<K extends keyof OfferingDraft>(
    field: K,
    value: OfferingDraft[K],
  ) {
    setDraft((current) => ({ ...current, [field]: value }));
    setError(null);
    setResult(null);
  }

  function updateKind(kind: OfferingKind) {
    setDraft((current) => ({ ...current, kind, expiry: "" }));
    setError(null);
    setResult(null);
  }

  function review(event: FormEvent) {
    event.preventDefault();
    const missing = Object.entries(draft).find(([, value]) => !value.trim());
    if (missing) {
      setError(
        "Complete target, outcome, eligibility, commercial limit, expiry, message and accountable owner.",
      );
      return;
    }
    setError(null);
    setReviewing(true);
  }

  async function submit() {
    if (result) {
      setError(null);
      return;
    }
    if (!confirmed) {
      setError("Confirm the user-facing promise and approval path.");
      return;
    }
    if (commandMode === "offline") {
      setError("You are offline. The draft was not created.");
      return;
    }
    if (commandMode === "denied") {
      setError("Your current role cannot create this offering.");
      return;
    }
    setBusy(true);
    setError(null);
    await new Promise((resolve) => setTimeout(resolve, 180));
    setBusy(false);
    if (failureMode && !failedOnce.current) {
      failedOnce.current = true;
      setError(
        "The offering draft was not created. Your inputs are saved here; retry the same action.",
      );
      return;
    }
    setResult("OFR-DRAFT-156-0719");
  }

  return (
    <div className="dialog-backdrop" role="presentation">
      <section
        aria-labelledby="offering-title"
        aria-modal="true"
        className="dialog dialog-wide"
        data-testid="offering-dialog"
        role="dialog"
      >
        <header className="dialog-header">
          <div>
            <p className="eyebrow">PROFILE-SPECIFIC PROVISIONING</p>
            <h2 id="offering-title">
              {reviewing ? "Review offering promise" : "Create an offering"}
            </h2>
            <p>
              A draft cannot reach users until its owner, funding, eligibility,
              policy and release checks pass.
            </p>
          </div>
          <button
            aria-label="Close offering composer"
            className="icon-button"
            data-testid="offering-close"
            type="button"
            onClick={onClose}
          >
            ×
          </button>
        </header>

        {!reviewing ? (
          <form className="dialog-scroll composer-form" onSubmit={review}>
            <div className="form-grid">
              <label>
                <span>Target user or workspace</span>
                <select
                  data-testid="offering-target"
                  value={draft.targetProfile}
                  onChange={(event) =>
                    update("targetProfile", event.target.value)
                  }
                >
                  <option value="">Choose one profile</option>
                  {adminProfileTargets.map((profile) => (
                    <option key={profile} value={profile}>
                      {profile}
                    </option>
                  ))}
                </select>
              </label>
              <label>
                <span>Offering type</span>
                <select
                  data-testid="offering-kind"
                  value={draft.kind}
                  onChange={(event) =>
                    updateKind(event.target.value as OfferingKind)
                  }
                >
                  {offeringKinds.map((kind) => (
                    <option key={kind} value={kind}>
                      {kind}
                    </option>
                  ))}
                </select>
              </label>
              <label className="form-wide">
                <span>Customer-facing name</span>
                <input
                  data-testid="offering-name"
                  value={draft.title}
                  onChange={(event) => update("title", event.target.value)}
                  placeholder="100 monthly basket customers"
                />
              </label>
              <label className="form-wide">
                <span>Result the user receives</span>
                <textarea
                  data-testid="offering-outcome"
                  value={draft.userOutcome}
                  onChange={(event) =>
                    update("userOutcome", event.target.value)
                  }
                  placeholder="State the measurable result and what counts as complete."
                />
              </label>
              <label className="form-wide">
                <span>Eligibility and readiness</span>
                <textarea
                  data-testid="offering-eligibility"
                  value={draft.eligibility}
                  onChange={(event) =>
                    update("eligibility", event.target.value)
                  }
                  placeholder="Verified profile, capability, capacity and consent requirements."
                />
              </label>
              <label>
                <span>Geography</span>
                <input
                  data-testid="offering-geography"
                  value={draft.geography}
                  onChange={(event) => update("geography", event.target.value)}
                  placeholder="Jodhpur pilot area"
                />
              </label>
              <label>
                <span>Maximum business exposure</span>
                <input
                  data-testid="offering-exposure"
                  value={draft.maximumExposure}
                  onChange={(event) =>
                    update("maximumExposure", event.target.value)
                  }
                  placeholder="₹50,000 maximum"
                />
              </label>
              <label>
                <span>Duration, expiry or stop condition</span>
                {draft.kind === "Business-funded Reel" ? (
                  <select
                    data-testid="offering-expiry"
                    value={draft.expiry}
                    onChange={(event) => update("expiry", event.target.value)}
                  >
                    <option value="">Choose 1–7 days</option>
                    {fundedReelDurations.map((duration) => (
                      <option key={duration} value={duration}>
                        {duration}
                      </option>
                    ))}
                  </select>
                ) : (
                  <input
                    data-testid="offering-expiry"
                    value={draft.expiry}
                    onChange={(event) => update("expiry", event.target.value)}
                    placeholder="Expiry date or an approved budget, capacity or safety stop"
                  />
                )}
              </label>
              <label>
                <span>Accountable owner</span>
                <input
                  data-testid="offering-owner"
                  value={draft.owner}
                  onChange={(event) => update("owner", event.target.value)}
                  placeholder="Retail Growth Operations"
                />
              </label>
              <label className="form-wide">
                <span>User-facing message and next action</span>
                <textarea
                  data-testid="offering-message"
                  value={draft.message}
                  onChange={(event) => update("message", event.target.value)}
                  placeholder="Tell the user what they can get and the exact next action."
                />
              </label>
            </div>
            {error && (
              <div
                className="message message-error"
                data-testid="offering-form-error"
                role="alert"
              >
                {error}
              </div>
            )}
            <div className="composer-sticky">
              <button
                className="button button-quiet"
                type="button"
                onClick={onClose}
              >
                Cancel
              </button>
              <button
                className="button button-primary"
                data-testid="offering-review"
                type="submit"
              >
                Review offering
              </button>
            </div>
          </form>
        ) : (
          <>
            <div className="dialog-scroll">
              <div className="offering-summary">
                <span>{draft.kind}</span>
                <h3>{draft.title}</h3>
                <p>{draft.message}</p>
              </div>
              <div className="facts">
                <div>
                  <span>TARGET</span>
                  <strong>{draft.targetProfile}</strong>
                </div>
                <div>
                  <span>AREA</span>
                  <strong>{draft.geography}</strong>
                </div>
                <div>
                  <span>MAXIMUM</span>
                  <strong>{draft.maximumExposure}</strong>
                </div>
                <div>
                  <span>STOP</span>
                  <strong>{draft.expiry}</strong>
                </div>
              </div>
              <section className="review-section">
                <h3>Measurable user result</h3>
                <p>{draft.userOutcome}</p>
                <h3>Eligibility and readiness</h3>
                <p>{draft.eligibility}</p>
                <h3>Accountable owner</h3>
                <p>{draft.owner}</p>
              </section>
              <div className="approval-path">
                <span>1 · Product owner</span>
                <span>2 · Finance and policy</span>
                <span>3 · Operations readiness</span>
                <span>4 · Controlled pilot group</span>
                <span>5 · Health-gated expansion</span>
              </div>
              <label className="confirmation">
                <input
                  checked={confirmed}
                  data-testid="offering-confirm"
                  type="checkbox"
                  onChange={(event) => setConfirmed(event.target.checked)}
                />
                <span>
                  I confirm the message makes no guaranteed claim beyond the
                  defined result and that no charge or launch occurs from this
                  draft.
                </span>
              </label>
              {error && (
                <div
                  className="message message-error"
                  data-testid="offering-error"
                  role="alert"
                >
                  {error}
                </div>
              )}
              {result && (
                <div
                  className="message message-success"
                  data-testid="offering-outcome-id"
                  role="status"
                >
                  <strong>
                    Offering draft created. It is not live and no budget was
                    charged.
                  </strong>
                  <span>Reference {result}</span>
                </div>
              )}
            </div>
            <footer className="dialog-footer">
              <button
                className="button button-quiet"
                type="button"
                onClick={() => {
                  setReviewing(false);
                  setConfirmed(false);
                  setError(null);
                }}
              >
                Edit details
              </button>
              <button
                className="button button-primary"
                data-testid="offering-submit"
                disabled={busy}
                type="button"
                onClick={submit}
              >
                {busy
                  ? "Creating…"
                  : result
                    ? "Draft created"
                    : "Create approval draft"}
              </button>
            </footer>
          </>
        )}
      </section>
    </div>
  );
}
