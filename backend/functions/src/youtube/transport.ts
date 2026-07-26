import type {
  HttpTransport,
  HttpTransportRequest,
  HttpTransportResponse,
} from "./types.js";
import { YouTubeProviderError } from "./errors.js";

const DEFAULT_TIMEOUT_MS = 15_000;
const MAX_CONFIGURED_RESPONSE_BYTES = 8 * 1024 * 1024;

function responseHeaders(headers: Headers): Record<string, string> {
  const result: Record<string, string> = {};
  headers.forEach((value, key) => {
    result[key.toLowerCase()] = value;
  });
  return result;
}

function responseByteLimit(value: number | undefined): number | undefined {
  if (value === undefined) return undefined;
  if (
    !Number.isSafeInteger(value) ||
    value < 1 ||
    value > MAX_CONFIGURED_RESPONSE_BYTES
  ) {
    throw new YouTubeProviderError(
      "bad_request",
      "The provider response limit is invalid.",
      400,
      false,
    );
  }
  return value;
}

async function boundedResponseBytes(
  response: Response,
  limit: number,
): Promise<Uint8Array> {
  const declaredLength = response.headers.get("content-length");
  if (
    declaredLength !== null &&
    /^\d+$/u.test(declaredLength) &&
    Number(declaredLength) > limit
  ) {
    await response.body?.cancel();
    throw new YouTubeProviderError(
      "provider_rejected",
      "The YouTube response exceeds the supported size.",
      502,
      false,
    );
  }
  if (!response.body) return new Uint8Array();
  const reader = response.body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  try {
    while (true) {
      const next = await reader.read();
      if (next.done) break;
      total += next.value.byteLength;
      if (total > limit) {
        await reader.cancel();
        throw new YouTubeProviderError(
          "provider_rejected",
          "The YouTube response exceeds the supported size.",
          502,
          false,
        );
      }
      chunks.push(next.value);
    }
  } finally {
    reader.releaseLock();
  }
  const output = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    output.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return output;
}

export class FetchHttpTransport implements HttpTransport {
  async send(request: HttpTransportRequest): Promise<HttpTransportResponse> {
    const limit = responseByteLimit(request.maxResponseBytes);
    const timeout = AbortSignal.timeout(DEFAULT_TIMEOUT_MS);
    const signal = request.signal
      ? AbortSignal.any([request.signal, timeout])
      : timeout;
    try {
      const response = await fetch(request.url, {
        method: request.method ?? "GET",
        ...(request.headers === undefined ? {} : { headers: request.headers }),
        ...(request.body === undefined ? {} : { body: request.body }),
        redirect: "manual",
        signal,
      });
      if (response.status >= 300 && response.status < 400) {
        throw new YouTubeProviderError(
          "provider_rejected",
          "YouTube returned an unexpected redirect.",
          502,
          false,
        );
      }
      const successful = response.status >= 200 && response.status < 300;
      const body =
        limit === undefined
          ? await response.text()
          : request.responseEncoding === "base64" && successful
            ? Buffer.from(
                await boundedResponseBytes(response, limit),
              ).toString("base64")
            : new TextDecoder("utf-8", { fatal: false }).decode(
                await boundedResponseBytes(response, limit),
              );
      return {
        status: response.status,
        headers: responseHeaders(response.headers),
        body,
      };
    } catch (error) {
      if (error instanceof YouTubeProviderError) throw error;
      throw new YouTubeProviderError(
        "provider_unavailable",
        "YouTube is temporarily unavailable.",
        503,
        true,
      );
    }
  }
}
