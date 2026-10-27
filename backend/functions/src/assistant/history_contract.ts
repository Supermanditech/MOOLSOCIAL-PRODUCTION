import {Buffer} from "node:buffer";
import type {AccountProfileActor} from "../account/profile_service.js";
import {decodePlansScope, type PlansScope} from "../account/plans_service.js";
import {object, text, id, fail, digest, preparationLanguages} from "./model_contract.js";

export const HISTORY_BYTES = 2 * 1024 * 1024;
export interface HistoryMessage {role: "user" | "assistant"; text: string}
export interface HistorySnapshot {
  id: string; revision: number; title: string; updatedAt: string;
  draft: string; language: string; messages: readonly HistoryMessage[];
}
export type HistorySummary = Pick<HistorySnapshot, "id" | "revision" | "title" | "updatedAt">;
export interface HistorySave {
  scope: PlansScope; requestId: string; clientKey: string;
  conversationId: string | null; expectedRevision: number;
  draft: string; language: string; messages: readonly HistoryMessage[];
}
export type HistoryCommand =
  {operation: "list"; payload: {scope: PlansScope; cursor: string | null}} |
  {operation: "read"; payload: {scope: PlansScope; id: string}} |
  {operation: "status"; payload: {scope: PlansScope; requestId: string}} |
  {operation: "save"; payload: HistorySave};
export type HistoryReceipt = {state: "pending"} | {state: "conflict"} |
  {state: "confirmed"; conversation: HistorySnapshot};
export interface HistoryIdentity {actor: AccountProfileActor; scope: PlansScope}
export function historyOwnerKey(i: HistoryIdentity): string {
  return digest([i.actor.projectId, i.actor.uid, i.scope.audience, i.scope.storeId]);
}
export function historyRequestKey(i: HistoryIdentity, requestId: string): string {
  return digest([historyOwnerKey(i), requestId]);
}
export function historyConversationKey(i: HistoryIdentity, conversationId: string): string {
  return digest([historyOwnerKey(i), conversationId]);
}
function content(raw: unknown, max: number): string {
  if (typeof raw !== "string" || raw.length > max || /[\u0000-\u0008\u000b\u000c\u000e-\u001f]/u.test(raw)) return fail("invalid_request", 400);
  if (Buffer.from(raw, "utf8").toString("utf8") !== raw) return fail("invalid_request", 400);
  return raw;
}
export function historyContent(raw: unknown): {draft: string; language: string; messages: HistoryMessage[]} {
  const p = object(raw, ["draft", "language", "messages"]);
  const draft = content(p.draft, 32000);
  if (typeof p.language !== "string" || !preparationLanguages.has(p.language) ||
      !Array.isArray(p.messages) || p.messages.length > 500) return fail("invalid_request", 400);
  const messages = p.messages.map(v => {
    const m = object(v, ["role", "text"]);
    if (m.role !== "user" && m.role !== "assistant") return fail("invalid_request", 400);
    return {role: m.role as "user" | "assistant", text: content(m.text, 32000)};
  });
  if (Buffer.byteLength(JSON.stringify(p), "utf8") > HISTORY_BYTES) return fail("history_too_large", 413);
  return {draft, language: p.language, messages};
}
export function historyCommand(raw: unknown): HistoryCommand {
  const row = object(raw, ["operation", "payload"]);
  switch (row.operation) {
    case "list": {
      const p = object(row.payload, ["scope", "cursor"]);
      return {operation: "list", payload: {scope: decodePlansScope(p.scope), cursor: p.cursor === null ? null : text(p.cursor, 2048)}};
    }
    case "read": {
      const p = object(row.payload, ["scope", "id"]);
      return {operation: "read", payload: {scope: decodePlansScope(p.scope), id: id(p.id)}};
    }
    case "status": {
      const p = object(row.payload, ["scope", "requestId"]);
      return {operation: "status", payload: {scope: decodePlansScope(p.scope), requestId: id(p.requestId)}};
    }
    case "save": {
      const p = object(row.payload, ["scope", "requestId", "clientKey", "conversationId", "expectedRevision", "draft", "language", "messages"]);
      const saved = historyContent({draft: p.draft, language: p.language, messages: p.messages});
      if (!saved.draft.trim() && !saved.messages.length) return fail("empty_history", 400);
      if (!Number.isSafeInteger(p.expectedRevision) || (p.expectedRevision as number) < 0 ||
          (p.conversationId === null) !== (p.expectedRevision === 0)) return fail("invalid_request", 400);
      return {operation: "save", payload: {...saved, scope: decodePlansScope(p.scope),
        requestId: id(p.requestId), clientKey: text(p.clientKey, 256),
        conversationId: p.conversationId === null ? null : id(p.conversationId), expectedRevision: p.expectedRevision as number}};
    }
    default: return fail("invalid_request", 400);
  }
}
export function decodeHistorySnapshot(raw: unknown): HistorySnapshot {
  const p = object(raw, ["id", "revision", "title", "updatedAt", "draft", "language", "messages"]);
  const saved = historyContent({draft: p.draft, language: p.language, messages: p.messages});
  if (!Number.isSafeInteger(p.revision) || (p.revision as number) < 1 ||
      typeof p.updatedAt !== "string" || !Number.isFinite(Date.parse(p.updatedAt)) ||
      new Date(p.updatedAt).toISOString() !== p.updatedAt) return fail("history_unavailable");
  return {...saved, id: id(p.id), revision: p.revision as number, title: text(p.title, 100), updatedAt: p.updatedAt};
}
export function historyTitle(draft: string, messages: readonly HistoryMessage[]): string {
  let preview = (messages.find(m => m.role === "user" && m.text.trim())?.text ?? draft).trim().replace(/\s+/gu, " ").slice(0, 90);
  const last = preview.charCodeAt(preview.length - 1);
  if (last >= 0xd800 && last <= 0xdbff) preview = preview.slice(0, -1);
  return preview || "Conversation";
}
