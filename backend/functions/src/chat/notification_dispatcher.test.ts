import assert from "node:assert/strict";
import test from "node:test";

import type { Firestore } from "firebase-admin/firestore";
import type { Messaging } from "firebase-admin/messaging";

import { FirebaseChatNotificationDispatcher } from "./notification_dispatcher.js";

test("dispatches privacy-safe preview to registered recipient device", async () => {
  const firestore = new FakeFirestore({
    "chatPrivacySettings/user-2": {
      messagesEnabled: true,
      showNotificationPreview: false,
      quietHoursEnabled: false,
    },
    "chatNotificationDevices/device-1": {
      userId: "user-2",
      token: "a".repeat(64),
    },
  });
  const messaging = new FakeMessaging();
  const dispatcher = new FirebaseChatNotificationDispatcher(
    firestore as unknown as Firestore,
    messaging as unknown as Messaging,
    () => new Date("2026-08-29T06:00:00.000Z"),
  );
  await dispatcher.dispatch({
    category: "message",
    recipientUserIds: ["user-2"],
    title: "Amit",
    preview: "Private message contents",
    data: { threadId: "thread-1" },
  });
  assert.equal(messaging.sent.length, 1);
  assert.equal(messaging.sent[0]?.notification?.body, "New message");
  assert.equal(messaging.sent[0]?.data?.threadId, "thread-1");
});

test("quiet hours suppress routine notification delivery", async () => {
  const firestore = new FakeFirestore({
    "chatPrivacySettings/user-2": {
      messagesEnabled: true,
      showNotificationPreview: true,
      quietHoursEnabled: true,
      quietStartMinutes: 22 * 60,
      quietEndMinutes: 7 * 60,
      utcOffsetMinutes: 0,
    },
    "chatNotificationDevices/device-1": {
      userId: "user-2",
      token: "a".repeat(64),
    },
  });
  const messaging = new FakeMessaging();
  const dispatcher = new FirebaseChatNotificationDispatcher(
    firestore as unknown as Firestore,
    messaging as unknown as Messaging,
    () => new Date("2026-08-29T23:00:00.000Z"),
  );
  await dispatcher.dispatch({
    category: "message",
    recipientUserIds: ["user-2"],
    title: "Amit",
    preview: "Hello",
    data: { threadId: "thread-1" },
  });
  assert.equal(messaging.sent.length, 0);
});

class FakeMessaging {
  readonly sent: Array<Record<string, any>> = [];

  async sendEachForMulticast(message: Record<string, any>) {
    this.sent.push(message);
    return {
      successCount: message.tokens.length,
      failureCount: 0,
      responses: message.tokens.map(() => ({ success: true })),
    };
  }
}

class FakeFirestore {
  readonly values: Map<string, Record<string, unknown>>;

  constructor(initial: Record<string, Record<string, unknown>>) {
    this.values = new Map(Object.entries(initial));
  }

  collection(path: string) {
    return new FakeCollection(this, path);
  }
}

class FakeCollection {
  private field?: string;
  private value?: unknown;

  constructor(
    private readonly firestore: FakeFirestore,
    private readonly path: string,
  ) {}

  doc(id: string) {
    return new FakeDocument(this.firestore, `${this.path}/${id}`);
  }

  where(field: string, _operator: string, value: unknown) {
    this.field = field;
    this.value = value;
    return this;
  }

  limit(_value: number) {
    return this;
  }

  async get() {
    const prefix = `${this.path}/`;
    const docs = [...this.firestore.values.entries()]
      .filter(([path, data]) =>
        path.startsWith(prefix) && !path.slice(prefix.length).includes("/") &&
        (this.field === undefined || data[this.field] === this.value)
      )
      .map(([path, data]) => ({
        id: path.slice(prefix.length),
        get: (field: string) => data[field],
        data: () => data,
      }));
    return { docs };
  }

  async add(data: Record<string, unknown>) {
    this.firestore.values.set(`${this.path}/failure`, data);
  }
}

class FakeDocument {
  constructor(
    private readonly firestore: FakeFirestore,
    private readonly path: string,
  ) {}

  async get() {
    const data = this.firestore.values.get(this.path);
    return { data: () => data, get: (field: string) => data?.[field] };
  }

  async delete() {
    this.firestore.values.delete(this.path);
  }
}
