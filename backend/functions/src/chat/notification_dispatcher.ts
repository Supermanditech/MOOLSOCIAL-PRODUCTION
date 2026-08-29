import { createHash } from "node:crypto";

import type { Firestore } from "firebase-admin/firestore";
import type { Messaging } from "firebase-admin/messaging";

import type {
  ChatNotificationDispatcher,
  ChatNotificationEvent,
  ChatNotificationPreferences,
} from "./contracts.js";

export class FirebaseChatNotificationDispatcher
implements ChatNotificationDispatcher {
  constructor(
    private readonly firestore: Firestore,
    private readonly messaging: Messaging,
    private readonly now: () => Date = () => new Date(),
  ) {}

  async dispatch(event: ChatNotificationEvent): Promise<void> {
    await Promise.all(event.recipientUserIds.map(async (userId) => {
      try {
        const preferences = await this.preferences(userId);
        if (!enabled(preferences, event.category) ||
            (event.category !== "call" &&
              inQuietHours(preferences, this.now()))) return;
        const devices = await this.firestore.collection("chatNotificationDevices")
          .where("userId", "==", userId)
          .limit(20)
          .get();
        const tokens = devices.docs.map((document) => String(document.get("token")))
          .filter((token) => token.length >= 32);
        if (tokens.length === 0) return;
        const response = await this.messaging.sendEachForMulticast({
          tokens,
          notification: {
            title: event.title,
            body: preferences.showPreview
              ? event.preview
              : categoryFallback(event.category),
          },
          data: { category: event.category, ...event.data },
          android: {
            priority: event.category === "call" ? "high" : "normal",
          },
          apns: {
            headers: {
              "apns-priority": event.category === "call" ? "10" : "5",
            },
            payload: {
              aps: event.category === "call" ? { sound: "default" } : {},
            },
          },
        });
        await Promise.all(response.responses.flatMap((item, index) => {
          const code = item.error?.code ?? "";
          if (code !== "messaging/registration-token-not-registered" &&
              code !== "messaging/invalid-registration-token") return [];
          return [this.firestore.collection("chatNotificationDevices")
            .doc(deviceId(userId, tokens[index]!)).delete()];
        }));
      } catch {
        await this.firestore.collection("chatNotificationFailures").add({
          schemaVersion: 1,
          userId,
          category: event.category,
          occurredAt: this.now().toISOString(),
          retryable: true,
        });
      }
    }));
  }

  private async preferences(userId: string): Promise<ChatNotificationPreferences> {
    const snapshot = await this.firestore.collection("chatPrivacySettings")
      .doc(userId).get();
    const data = snapshot.data();
    return {
      messagesEnabled: data?.messagesEnabled !== false,
      callsEnabled: data?.callsEnabled !== false,
      groupInvitesEnabled: data?.groupInvitesEnabled !== false,
      showPreview: data?.showNotificationPreview !== false,
      quietHoursEnabled: data?.quietHoursEnabled === true,
      quietStartMinutes: boundedMinutes(data?.quietStartMinutes, 22 * 60),
      quietEndMinutes: boundedMinutes(data?.quietEndMinutes, 7 * 60),
      utcOffsetMinutes: boundedOffset(data?.utcOffsetMinutes),
      updatedAt: String(data?.updatedAt ?? ""),
    };
  }
}

function enabled(
  preferences: ChatNotificationPreferences,
  category: ChatNotificationEvent["category"],
): boolean {
  return category === "message"
    ? preferences.messagesEnabled
    : category === "call"
      ? preferences.callsEnabled
      : preferences.groupInvitesEnabled;
}

function inQuietHours(
  preferences: ChatNotificationPreferences,
  now: Date,
): boolean {
  if (!preferences.quietHoursEnabled) return false;
  const local = new Date(now.getTime() + preferences.utcOffsetMinutes * 60_000);
  const minutes = local.getUTCHours() * 60 + local.getUTCMinutes();
  const start = preferences.quietStartMinutes;
  const end = preferences.quietEndMinutes;
  if (start === end) return true;
  return start < end
    ? minutes >= start && minutes < end
    : minutes >= start || minutes < end;
}

function categoryFallback(category: ChatNotificationEvent["category"]): string {
  return category === "call"
    ? "Incoming call"
    : category === "group_invite"
      ? "New group invitation"
      : "New message";
}

function boundedMinutes(value: unknown, fallback: number): number {
  return Number.isSafeInteger(value) && (value as number) >= 0 &&
      (value as number) < 1440
    ? value as number
    : fallback;
}

function boundedOffset(value: unknown): number {
  return Number.isSafeInteger(value) && (value as number) >= -840 &&
      (value as number) <= 840
    ? value as number
    : 0;
}

export function deviceId(userId: string, token: string): string {
  return createHash("sha256").update(`${userId}:${token}`).digest("hex");
}
