import { createHash } from "node:crypto";

import type { DataConnect } from "firebase-admin/data-connect";

import type {
  YouTubeAuditEvent,
  YouTubeAuditPort,
} from "./ports.js";
import { redactSensitiveData } from "./redaction.js";

const EVENT_TYPE = /^[a-z][a-z0-9_.-]{2,79}$/u;
const MAX_REQUEST_ID_LENGTH = 128;
const MAX_USER_ID_LENGTH = 128;
const MAX_DETAIL_BYTES = 16_384;

export interface PreparedYouTubeAuditEvent {
  readonly eventKey: string;
  readonly userId?: string;
  readonly eventType: string;
  readonly requestId: string;
  readonly redactedDetailJson: string;
  readonly occurredAt: string;
}

function eventKey(event: YouTubeAuditEvent): string {
  const digest = createHash("sha256")
    .update(
      [
        "YOUTUBE",
        event.userId ?? "-",
        event.eventType,
        event.requestId,
      ].join("\u001f"),
      "utf8",
    )
    .digest("base64url");
  return `yta_${digest}`;
}

function validate(event: YouTubeAuditEvent): void {
  if (!EVENT_TYPE.test(event.eventType)) {
    throw new Error("YouTube audit event type is invalid.");
  }
  if (
    event.requestId.length < 1 ||
    event.requestId.length > MAX_REQUEST_ID_LENGTH
  ) {
    throw new Error("YouTube audit request ID is invalid.");
  }
  if (
    event.userId !== undefined &&
    (event.userId.length < 1 || event.userId.length > MAX_USER_ID_LENGTH)
  ) {
    throw new Error("YouTube audit user ID is invalid.");
  }
  if (!Number.isFinite(Date.parse(event.occurredAt))) {
    throw new Error("YouTube audit timestamp is invalid.");
  }
}

function redactedDetail(event: YouTubeAuditEvent): string {
  const value = JSON.stringify(redactSensitiveData(event.detail));
  if (Buffer.byteLength(value, "utf8") > MAX_DETAIL_BYTES) {
    throw new Error("YouTube audit detail exceeds the safe size limit.");
  }
  return value;
}

/**
 * Produces the one validated, redacted representation used by every durable
 * YouTube audit adapter. Keeping this boundary shared prevents a persistence
 * migration from weakening credential redaction or idempotency.
 */
export function prepareYouTubeAuditEvent(
  event: YouTubeAuditEvent,
): PreparedYouTubeAuditEvent {
  validate(event);
  return {
    eventKey: eventKey(event),
    ...(event.userId === undefined ? {} : { userId: event.userId }),
    eventType: event.eventType,
    requestId: event.requestId,
    redactedDetailJson: redactedDetail(event),
    occurredAt: event.occurredAt,
  };
}

/**
 * Append-only, server-owned audit evidence. A repeated event from the same
 * request is idempotent and never exposes raw provider credentials.
 */
export class DataConnectYouTubeAuditStore implements YouTubeAuditPort {
  constructor(private readonly dataConnect: DataConnect) {}

  async record(event: YouTubeAuditEvent): Promise<void> {
    const prepared = prepareYouTubeAuditEvent(event);
    await this.dataConnect.executeGraphql<
      unknown,
      {
        eventKey: string;
        userId: string | null;
        eventType: string;
        requestId: string;
        redactedDetailJson: string;
        occurredAt: string;
      }
    >(
      `mutation RecordYouTubeAuditEvent(
        $eventKey: String!
        $userId: String
        $eventType: String!
        $requestId: String!
        $redactedDetailJson: String!
        $occurredAt: Timestamp!
      ) {
        _execute(
          sql: """
            INSERT INTO provider_audit_event
              (
                event_key,
                user_id,
                provider,
                event_type,
                request_id,
                redacted_detail_json,
                occurred_at
              )
            VALUES ($1, $2, 'YOUTUBE', $3, $4, $5, $6)
            ON CONFLICT (event_key) DO NOTHING
          """
          params: [
            $eventKey
            $userId
            $eventType
            $requestId
            $redactedDetailJson
            $occurredAt
          ]
        )
      }`,
      {
        variables: {
          eventKey: prepared.eventKey,
          userId: prepared.userId ?? null,
          eventType: prepared.eventType,
          requestId: prepared.requestId,
          redactedDetailJson: prepared.redactedDetailJson,
          occurredAt: prepared.occurredAt,
        },
      },
    );
  }
}
