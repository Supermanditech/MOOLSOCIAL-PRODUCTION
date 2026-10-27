import {Buffer} from "node:buffer";
import type {AccountProfileActor} from "../account/profile_service.js";
import type {AccountPlansService} from "../account/plans_service.js";
import {canonical, digest, fail, id, object} from "./model_contract.js";
import {historyOwnerKey, historyTitle, type HistoryCommand,
  type HistoryIdentity, type HistorySnapshot} from "./history_contract.js";
import type {HistoryRepository} from "./history_dataconnect_store.js";

interface Cursor {ownerKey: string; accessRevision: string; upper: string; afterAt: string; afterId: string}
export class AssistantHistoryService {
  constructor(private readonly deps: {projectId: string; plans: Pick<AccountPlansService, "read">;
    repository: HistoryRepository; now?: () => Date}) {}
  private now() {return this.deps.now?.() ?? new Date();}
  private async access(i: HistoryIdentity) {
    if (!i.actor.uid || i.actor.projectId !== this.deps.projectId || i.actor.tenantId !== undefined) return fail("account_scope_mismatch", 403);
    // The existing Plans service validates active account and current approved
    // Workspace membership. Stored chat text is never an access credential.
    const value = await this.deps.plans.read(i.actor, i.scope);
    const until = Date.parse(value.validUntil);
    if (!value.activeFeatureIds.includes("mool_ai") || !Number.isFinite(until) || until <= this.now().getTime()) return fail("ai_access_required", 403);
    return {revision: canonical([i.scope, value.catalogueRevision, value.subscriptionRevision]), until};
  }
  private async recheck(i: HistoryIdentity, before: {revision: string; until: number}) {
    const after = await this.access(i);
    if (after.revision !== before.revision || before.until <= this.now().getTime()) return fail("history_access_changed", 409);
  }
  private cursor(raw: string, i: HistoryIdentity, revision: string): Cursor {
    try {
      if (!/^[A-Za-z0-9_-]+$/u.test(raw)) return fail("invalid_history_cursor", 400);
      const p = object(JSON.parse(Buffer.from(raw, "base64url").toString("utf8")),
        ["ownerKey", "accessRevision", "upper", "afterAt", "afterId"]);
      if (p.ownerKey !== historyOwnerKey(i) || p.accessRevision !== revision) return fail("history_access_changed", 409);
      for (const key of ["upper", "afterAt"]) {
        if (typeof p[key] !== "string" || !Number.isFinite(Date.parse(p[key] as string)) ||
            new Date(p[key] as string).toISOString() !== p[key]) return fail("invalid_history_cursor", 400);
      }
      if (Date.parse(p.upper as string) > this.now().getTime() || (p.afterAt as string) > (p.upper as string)) return fail("invalid_history_cursor", 400);
      return {...p, afterId: id(p.afterId)} as unknown as Cursor;
    } catch {return fail("invalid_history_cursor", 400);}
  }
  async handle(actor: AccountProfileActor, command: HistoryCommand) {
    const i = {actor, scope: command.payload.scope}, before = await this.access(i);
    const envelope = {ownerKey: historyOwnerKey(i), scope: i.scope};
    const repository = this.deps.repository;
    switch (command.operation) {
      case "list": {
        const saved = command.payload.cursor ? this.cursor(command.payload.cursor, i, before.revision) : null;
        const upper = saved?.upper ?? this.now().toISOString();
        const rows = await repository.list(i, upper, saved?.afterAt ?? "", saved?.afterId ?? "");
        if (rows.length > 21 || new Set(rows.map(r => r.id)).size !== rows.length ||
            rows.some(row => row.updatedAt > upper)) return fail("history_unavailable");
        const items = rows.slice(0, 20), last = items.at(-1);
        const nextCursor = rows.length > 20 && last ? Buffer.from(JSON.stringify({
          ownerKey: envelope.ownerKey, accessRevision: before.revision, upper,
          afterAt: last.updatedAt, afterId: last.id,
        })).toString("base64url") : null;
        await this.recheck(i, before);
        return {...envelope, items, nextCursor};
      }
      case "read": {
        const conversation = await repository.read(i, command.payload.id) ?? fail("history_not_found", 404);
        if (conversation.id !== command.payload.id) return fail("history_unavailable");
        await this.recheck(i, before);
        return {...envelope, conversation};
      }
      case "status": {
        const receipt = await repository.status(i, command.payload.requestId) ?? fail("history_request_not_found", 404);
        await this.recheck(i, before);
        return {...envelope, ...receipt};
      }
      case "save": {
        const s = command.payload;
        let receipt = await repository.claim(i, s, this.now().toISOString(), before.revision);
        if (receipt.state === "pending") {
          // A late request that had not yet claimed its receipt must not create
          // a second chat for the same editor after a newer original save.
          const conversationId = s.conversationId ?? "c_" + digest(["history-editor", historyOwnerKey(i), s.clientKey]);
          const snapshot: HistorySnapshot = {id: conversationId, revision: s.expectedRevision + 1,
            title: historyTitle(s.draft, s.messages), updatedAt: this.now().toISOString(),
            draft: s.draft, language: s.language, messages: s.messages};
          await this.recheck(i, before);
          receipt = await repository.commit(i, s, snapshot);
        }
        await this.recheck(i, before);
        return {...envelope, ...receipt};
      }
    }
  }
}
