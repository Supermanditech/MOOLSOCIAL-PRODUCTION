import {verifySocialInvocation, type VerifiedSocialAppCheck} from "../social/request_security.js";
import {SocialContentError} from "../social/contracts.js";
import type {AccountProfileActor} from "../account/profile_service.js";
import {AccountPlansError} from "../account/plans_service.js";
import {AssistantModelError} from "./model_contract.js";
import {HISTORY_BYTES, historyCommand} from "./history_contract.js";
import type {AssistantHistoryService} from "./history_service.js";

export interface AssistantHistoryHttpDependencies {
  projectId: string; enabled: boolean; service?: Pick<AssistantHistoryService, "handle">;
  verifyAppCheck(token: string, consume: boolean): Promise<VerifiedSocialAppCheck>;
  verifyIdToken(token: string): Promise<AccountProfileActor & {anonymous?: boolean}>;
}
export async function handleAssistantHistoryRequest(input: {method: string;
  headers: Readonly<Record<string, string | string[] | undefined>>; body: unknown; bodyBytes: number},
deps: AssistantHistoryHttpDependencies) {
  try {
    if (input.method !== "POST") throw new AssistantModelError("invalid_request", 405);
    if (!Number.isSafeInteger(input.bodyBytes) || input.bodyBytes < 0 || input.bodyBytes > HISTORY_BYTES + 16384) throw new AssistantModelError("history_too_large", 413);
    const command = historyCommand(input.body);
    let actor: AccountProfileActor | undefined;
    await verifySocialInvocation(input.headers, {
      verifyAppCheck: (token, consume) => deps.verifyAppCheck(token, consume),
      verifyIdToken: async token => {
        const who = await deps.verifyIdToken(token);
        if (who.anonymous || who.projectId !== deps.projectId || who.tenantId !== undefined) throw new AssistantModelError("account_scope_mismatch", 403);
        actor = who; return {uid: who.uid};
      },
    }, command.operation === "save", true);
    if (!actor) throw new AssistantModelError("authentication_required", 401);
    if (!deps.enabled || !deps.service) throw new AssistantModelError("history_unavailable");
    const data = await deps.service.handle(actor, command);
    return {status: 200, body: {ok: true as const, data}};
  } catch (error) {
    const known = error instanceof AssistantModelError || error instanceof AccountPlansError;
    const status = known ? error.status : error instanceof SocialContentError ? error.httpStatus : 503;
    const code = known || error instanceof SocialContentError ? error.code : "history_unavailable";
    return {status, body: {ok: false as const, error: {code, message: "Chat history could not complete this request. Keep your current request open and try again."}}};
  }
}
