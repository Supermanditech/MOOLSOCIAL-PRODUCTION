# LF-25 — Store owner applies customer terms only from the current editor

Existing LF05 child, mvp_supporting. Retailer/Grocery Store owner edits private
payment preferences for one existing customer. A callback from another account,
an earlier Store A->B->A visit, a disposed form or a retargeted customer must not
write the destination customer's preferences. Demonstrate the gap before repair.

Source: StoreCustomerPaymentTerms initializes its draft lazily and its callback
passes only Store/customer IDs. saveWorkspaceCustomerPaymentTerms checks those
IDs but has no captured caller context. Existing sheet keys and _sameCustomer
also do not establish account/navigation lifetime. This is a suspected stale-write
gap until reproduced; source inspection alone does not prove a native data leak.

Reuse publicationPreferencesContext (account, Store, navigation revision), the
existing private map, editor and validation. Capture context eagerly at draft
initialization, require it at the session mutation boundary, and reject disposed
or superseded widget callbacks. Deliberate widget retargeting initializes that
customer's draft; account/context drift must not silently rebind an old draft.
Use the existing section for a concise reopen message, no new route or identity.

Acceptance: normal/200% stale account and Store ABA callbacks preserve the exact
destination map; disposed and retargeted callbacks do not write; valid same-context
override and inheritance still work, invalid terms remain rejected. Preserve
customer-map exclusion from public products, Stock, invoices and schema. Update
every internal caller of the context-required mutation, with focused model/widget
and affected full-editor regressions. OPPO source reload and existing customer
section inspection only; no Apply, customer/Stock/financial/provider changes.

Overnight verified-defect authority permits this supported correction while
morning founder approval remains pending. Keep one writer, existing ownership/
secret/founder checks and coherent local checkpoint; no policy/registry expansion,
backend, APK, push or other tree. Scope is stale caller safety, not a new auth
generation system, server Store permission, customer merge or legacy migration.

Customer keys still may be payment IDs, phone or normalized names. No durable
replay of those keys as authenticated buyer terms, credit grant, quote, policy
consent or real order outcome. Those identities and provider contracts remain
explicitly unfinished. Unobserved same-account sign-out/relogin generations are
not proven by the existing account/Store/navigation tuple.

## Implemented checkpoint evidence — 16 October 2026

Founder explicitly resumed frontend implementation and clarified sole Codex
ownership of the combined baseline. Only literal LF25 ticket/path entries were
added to the two existing checks;92-owner implementation admission passed, with
safety predicates, historical policy and registry unchanged. Amended founder
source43 was read completely through END SOURCE and the decision Check passed.

Failing-before: two normal/200% host widget cases invoked the original Apply
callback after account change. Destination publication data gained the old
customer's explicit empty override, contrary to exact-map preservation. This
demonstrates a host callback defect, not proven native leakage or server access.

WorkSession now requires the captured publicationPreferencesContext and rejects
disposed/context-mismatched calls before mutation. The existing editor eagerly
initializes its draft/context, reinitializes only deliberate session/Store/customer
retargets, keys nested input state by its binding and rejects obsolete callbacks.
Context drift shows a reopen message in the existing section. Both mutation and
delegated publication save are synchronous; no awaited completion applies terms
later. Every existing internal caller was updated; no schema or identities changed.

139 settings/publication tests passed, including12 new LF25 cases: three direct
session refusals, eight normal/200% account/Store-ABA/disposed/retarget callbacks,
and current override/invalid/empty/inheritance behavior. Two affected complete
customer-detail PAYMENT-TERMS UI journeys also passed at360 and320/200%.
Analysis:0 errors/warnings, one unchanged layout-test brace-style info at52854.
Private customer-map exclusion remains covered by existing publication tests.
These results do not prove durable customer terms or live policy/credit authority.

OPPO2b3e0f71: old attachment had ended; same debuggable r67.3-runtime/code2026101303
was relaunched and reattached, without build/install/reset. Initial0-library
reload was not treated as loading proof. Source restart3474ms followed by actual
VM script readback confirms required session context and widget binding guards
are running. Uninitialized VM const fields and unavailable expression compilation
did not establish runtime define values; no such verification claim is made.

One Workspace tap restored TEST Store: Stock29550,18 low,24 available/6 unavailable.
Read-only Profile -> Operations -> Customer records -> existing customer ->
Wholesale payment terms expansion retains11 orders/4676.90 spent/1500 due and
Store-default selection. Actual saved screenshot inspected at calling task
outputs/lf25-customer-terms-20261016.png. No Apply, switch edit, call, Chat,
WhatsApp, repeat sale, invoice, offer, consent or provider action was performed.
Physical account/Store races remain host-only; normal native layout inspected,
200% coverage is host evidence. Adjacent existing sheet title ellipsis remains a
separate customer-records visual finding, not silently asserted fixed here.

Development corrections: patch boundary assertion prevented a wrong-line edit;
const Padding around non-const Semantics failed compilation and was corrected;
four teardown failures were24ms Review gateway saves, settled in the harness;
an APP-cwd read used a ROOT prefix and failed without source loss; reversed patch
hunks were rejected atomically and reordered. No failed run was counted passed.
Architect context-only review confirmed both session and widget guards are needed;
no wider authentication or identity redesign indicated.

Status: implemented/tested/source-loaded; founder acceptance pending. This closes
only the demonstrated stale-editor defect, not LF05 or the full mapped frontend.
