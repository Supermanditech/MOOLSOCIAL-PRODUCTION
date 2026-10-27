import {verifySocialInvocation, type VerifiedSocialAppCheck} from "../social/request_security.js";
import {SocialContentError} from "../social/contracts.js";
import type {AccountProfileActor} from "../account/profile_service.js";
import {AccountPlansError} from "../account/plans_service.js";
import {AssistantModelError, command} from "./model_contract.js";
import type {AssistantPreparationService} from "./model_service.js";

export interface AssistantModelHttpDependencies {
  projectId: string; enabled: boolean; service: AssistantPreparationService;
  verifyAppCheck(token: string, consume: boolean): Promise<VerifiedSocialAppCheck>;
  verifyIdToken(token: string): Promise<AccountProfileActor & {anonymous?: boolean}>;
}
export async function handleAssistantModelRequest(input: {method: string; headers: Readonly<Record<string, string | string[] | undefined>>; body: unknown; bodyBytes: number}, deps: AssistantModelHttpDependencies) {
  try {
    if (input.method !== "POST") throw new AssistantModelError("invalid_request", 405);
    if (!Number.isSafeInteger(input.bodyBytes) || input.bodyBytes < 0 || input.bodyBytes > 64 * 1024) throw new AssistantModelError("invalid_request", 413);
    const cmd = command(input.body);
    let actor: AccountProfileActor | undefined;
    await verifySocialInvocation(input.headers, {verifyAppCheck: (t, c) => deps.verifyAppCheck(t, c), verifyIdToken: async token => {
      const who = await deps.verifyIdToken(token);
      if (who.anonymous || who.projectId !== deps.projectId || who.tenantId !== undefined) throw new AssistantModelError("account_scope_mismatch", 403);
      actor = who; return {uid: who.uid};
    }}, false, true);
    if (!actor) throw new AssistantModelError("authentication_required", 401);
    if (!deps.enabled) throw new AssistantModelError();
    const data = await deps.service.handle(actor, cmd);
    return {status: 200, body: {ok: true as const, data}};
  } catch (error) {
    const known = error instanceof AssistantModelError || error instanceof AccountPlansError;
    const status = known ? error.status : error instanceof SocialContentError ? error.httpStatus : 503;
    const code = known || error instanceof SocialContentError ? error.code : "assistant_unavailable";
    return {status, body: {ok: false as const, error: {code, message: "Mool AI could not prepare this request. Your app records are unchanged."}}};
  }
}
