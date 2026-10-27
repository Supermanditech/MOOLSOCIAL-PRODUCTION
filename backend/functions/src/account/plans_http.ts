import {SocialContentError} from "../social/contracts.js";
import {verifySocialInvocation, type VerifiedSocialAppCheck} from "../social/request_security.js";
import type {AccountProfileActor} from "./profile_service.js";
import {AccountPlansError, decodePlansScope, type AccountPlansService} from "./plans_service.js";

export interface AccountPlansHttpDependencies {
  readonly projectId: string;
  readonly storageQualified: boolean;
  readonly service: AccountPlansService;
  verifyAppCheck(token: string, consume: boolean): Promise<VerifiedSocialAppCheck>;
  verifyIdToken(token: string): Promise<AccountProfileActor & {readonly anonymous?: boolean}>;
}
export interface AccountPlansHttpInput {
  readonly method: string; readonly headers: Readonly<Record<string, string | string[] | undefined>>;
  readonly body: unknown; readonly bodyBytes: number;
}
function message(code: string): string {
  if (["account_scope_mismatch", "authentication_required"].includes(code)) return "Sign in again to view your plans.";
  if (code === "workspace_access_unavailable") return "Store access could not be confirmed. Your personal plans remain separate.";
  if (code === "invalid_plans_request") return "Choose the account or Store whose plans you want to view.";
  return "Plans are not available right now. Try again later.";
}
export async function handleAccountPlansRequest(input: AccountPlansHttpInput, deps: AccountPlansHttpDependencies) {
  try {
    if (input.method !== "POST") throw new AccountPlansError("invalid_plans_request", 405);
    if (!Number.isSafeInteger(input.bodyBytes) || input.bodyBytes < 0 || input.bodyBytes > 4096) throw new AccountPlansError("invalid_plans_request", 413);
    if (!input.body || typeof input.body !== "object" || Array.isArray(input.body)) throw new AccountPlansError("invalid_plans_request", 400);
    const body = input.body as Record<string, unknown>;
    if (Object.keys(body).sort().join("|") !== "operation|payload" || body.operation !== "read") throw new AccountPlansError("invalid_plans_request", 400);
    let scope;
    try { scope = decodePlansScope(body.payload); } catch { throw new AccountPlansError("invalid_plans_request", 400); }
    let actor: AccountProfileActor | undefined;
    const uid = await verifySocialInvocation(input.headers, {
      verifyAppCheck: (token, consume) => deps.verifyAppCheck(token, consume),
      verifyIdToken: async token => {
        const principal = await deps.verifyIdToken(token);
        if (principal.anonymous || principal.projectId !== deps.projectId || principal.tenantId !== undefined) throw new AccountPlansError("account_scope_mismatch", 403);
        actor = principal;
        return {uid: principal.uid};
      },
    }, false, true);
    if (!actor || !uid || actor.uid !== uid) throw new AccountPlansError("authentication_required", 401);
    if (!deps.storageQualified) throw new AccountPlansError("plans_unavailable");
    const data = await deps.service.read(actor, scope);
    return {status: 200, body: {ok: true as const, data}};
  } catch (error) {
    const code = error instanceof AccountPlansError || error instanceof SocialContentError ? error.code : "plans_unavailable";
    const status = error instanceof AccountPlansError ? error.status : error instanceof SocialContentError ? error.httpStatus : 503;
    return {status, body: {ok: false as const, error: {code, message: message(code)}}};
  }
}
