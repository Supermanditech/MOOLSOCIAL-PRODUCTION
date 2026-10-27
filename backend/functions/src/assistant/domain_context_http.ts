import {verifySocialInvocation, type VerifiedSocialAppCheck} from "../social/request_security.js";
import {SocialContentError} from "../social/contracts.js";
import {AccountPlansError} from "../account/plans_service.js";
import type {AccountProfileActor} from "../account/profile_service.js";
import {AssistantModelError} from "./model_contract.js";
import type {PreparationContextSource} from "./model_service.js";
import {canonicalContextProjection, canonicalContextRequest, contextReadSelection} from "./domain_context_contract.js";

export interface AssistantCanonicalContextHttpDependencies {
  projectId: string; enabled: boolean; context?: PreparationContextSource;
  verifyAppCheck(token: string, consume: boolean): Promise<VerifiedSocialAppCheck>;
  verifyIdToken(token: string): Promise<AccountProfileActor & {anonymous?: boolean}>;
  now?: () => Date;
}
/** Read-only metadata endpoint: no request store, model, upload or effect port. */
export async function handleAssistantCanonicalContextRequest(input: {method: string;
  headers: Readonly<Record<string, string | string[] | undefined>>;
  body: unknown; bodyBytes: number}, deps: AssistantCanonicalContextHttpDependencies) {
  try {
    if (input.method !== "POST") throw new AssistantModelError("invalid_request", 405);
    if (!Number.isSafeInteger(input.bodyBytes) || input.bodyBytes < 0 || input.bodyBytes > 64 * 1024) {
      throw new AssistantModelError("invalid_request", 413);
    }
    const selection = canonicalContextRequest(input.body), scope = selection.scope;
    let actor: AccountProfileActor | undefined;
    await verifySocialInvocation(input.headers, {verifyAppCheck: (token, consume) => deps.verifyAppCheck(token, consume),
      verifyIdToken: async token => {
        const who = await deps.verifyIdToken(token);
        if (who.anonymous || !who.uid || who.projectId !== deps.projectId || who.tenantId !== undefined) {
          throw new AssistantModelError("account_scope_mismatch", 403);
        }
        actor = who; return {uid: who.uid};
      }}, false, false);
    if (!actor) throw new AssistantModelError("authentication_required", 401);
    if (!deps.enabled || !deps.context) throw new AssistantModelError("context_unavailable");
    const current = await deps.context.read(actor, contextReadSelection(scope, selection.catalogueListingIds));
    const until = Date.parse(current.validUntil), now = (deps.now?.() ?? new Date()).getTime();
    if (!Number.isFinite(until) || until <= now || new Date(until).toISOString() !== current.validUntil) {
      throw new AssistantModelError("stale_preparation", 409);
    }
    return {status: 200, body: {ok: true as const,
      data: canonicalContextProjection(actor, scope, current)}};
  } catch (error) {
    const known = error instanceof AssistantModelError || error instanceof AccountPlansError;
    const status = known ? error.status : error instanceof SocialContentError ? error.httpStatus : 503;
    const code = known || error instanceof SocialContentError ? error.code : "context_unavailable";
    return {status, body: {ok: false as const, error: {code,
      message: "Mool AI could not read the current source. Your app records are unchanged."}}};
  }
}
