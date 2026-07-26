import assert from "node:assert/strict";
import test from "node:test";

import {
  DEFAULT_YOUTUBE_WEBSUB_ATOM_LIMITS,
  YouTubeWebSubAtomError,
  parseYouTubeWebSubAtomFeed,
} from "./websub_atom.js";

const CHANNEL_ID = `UC${"a".repeat(22)}`;
const OTHER_CHANNEL_ID = `UC${"b".repeat(22)}`;
const VIDEO_ID = "A1b2C3d4E5f";
const SECOND_VIDEO_ID = "Z9y8X7w6V5u";
const ATOM_NAMESPACE = "http://www.w3.org/2005/Atom";
const YOUTUBE_NAMESPACE =
  "http://www.youtube.com/xml/schemas/2015";
const MEDIA_NAMESPACE =
  "http://search.yahoo.com/mrss/";
const TOMBSTONE_NAMESPACE =
  "http://purl.org/atompub/tombstones/1.0";

function bytes(value: string): Buffer {
  return Buffer.from(value, "utf8");
}

function entry(
  videoId = VIDEO_ID,
  channelId = CHANNEL_ID,
  updatedAt = "2026-07-24T00:01:00Z",
): string {
  return `
    <entry>
      <id>yt:video:${videoId}</id>
      <yt:videoId>${videoId}</yt:videoId>
      <yt:channelId>${channelId}</yt:channelId>
      <title>Safe &amp; current title</title>
      <published>2026-07-24T00:00:00Z</published>
      <updated>${updatedAt}</updated>
    </entry>`;
}

function feed(
  contents = entry(),
  selfPath = "/feeds/videos.xml",
): Buffer {
  return bytes(`<?xml version="1.0" encoding="UTF-8"?>
  <feed xmlns="${ATOM_NAMESPACE}"
        xmlns:yt="${YOUTUBE_NAMESPACE}"
        xmlns:at="${TOMBSTONE_NAMESPACE}">
    <link rel="hub" href="https://pubsubhubbub.appspot.com/"/>
    <link rel="self"
      href="https://www.youtube.com${selfPath}?channel_id=${CHANNEL_ID}"/>
    <updated>2026-07-24T00:02:00Z</updated>
    ${contents}
  </feed>`);
}

function officialDocumentedFeedFixture(): Buffer {
  return bytes(`
    <feed xmlns:yt="${YOUTUBE_NAMESPACE}"
          xmlns="${ATOM_NAMESPACE}">
      <link rel="hub" href="https://pubsubhubbub.appspot.com"/>
      <link rel="self"
        href="https://www.youtube.com/xml/feeds/videos.xml?channel_id=${CHANNEL_ID}"/>
      <title>YouTube video feed</title>
      <updated>2015-04-01T19:05:24.552394234+00:00</updated>
      <entry>
        <id>yt:video:${VIDEO_ID}</id>
        <yt:videoId>${VIDEO_ID}</yt:videoId>
        <yt:channelId>${CHANNEL_ID}</yt:channelId>
        <title>Video title</title>
        <link rel="alternate"
          href="http://www.youtube.com/watch?v=${VIDEO_ID}"/>
        <author>
          <name>Channel title</name>
          <uri>http://www.youtube.com/channel/${CHANNEL_ID}</uri>
        </author>
        <published>2015-03-06T21:40:57+00:00</published>
        <updated>2015-03-09T19:05:24.552394234+00:00</updated>
      </entry>
    </feed>`);
}

function realisticVideoId(index: number): string {
  return `v${index.toString().padStart(10, "0")}`;
}

function realisticEntry(index: number): string {
  const videoId = realisticVideoId(index);
  return `
    <entry>
      <id>yt:video:${videoId}</id>
      <yt:videoId>${videoId}</yt:videoId>
      <yt:channelId>${CHANNEL_ID}</yt:channelId>
      <title>Provider video ${index}</title>
      <link rel="alternate"
        href="https://www.youtube.com/watch?v=${videoId}"/>
      <author>
        <name>Provider channel</name>
        <uri>https://www.youtube.com/channel/${CHANNEL_ID}</uri>
      </author>
      <published>2026-07-24T00:00:00+00:00</published>
      <updated>2026-07-24T00:01:00.000000000+00:00</updated>
      <media:group>
        <media:title>Provider video ${index}</media:title>
        <media:content
          url="https://www.youtube.com/v/${videoId}?version=3"
          type="application/x-shockwave-flash"
          width="640"
          height="390"/>
        <media:thumbnail
          url="https://i1.ytimg.com/vi/${videoId}/hqdefault.jpg"
          width="480"
          height="360"/>
        <media:description>Current provider feed metadata.</media:description>
        <media:community>
          <media:starRating count="1" average="5.00" min="1" max="5"/>
          <media:statistics views="${index}"/>
        </media:community>
      </media:group>
    </entry>`;
}

function realisticFullFeedFixture(entryCount = 15): Buffer {
  return bytes(`
    <feed xmlns:yt="${YOUTUBE_NAMESPACE}"
          xmlns:media="${MEDIA_NAMESPACE}"
          xmlns="${ATOM_NAMESPACE}">
      <link rel="hub" href="https://pubsubhubbub.appspot.com"/>
      <link rel="self"
        href="http://www.youtube.com/feeds/videos.xml?channel_id=${CHANNEL_ID}"/>
      <id>yt:channel:${CHANNEL_ID}</id>
      <yt:channelId>${CHANNEL_ID}</yt:channelId>
      <title>Provider channel</title>
      <link rel="alternate"
        href="https://www.youtube.com/channel/${CHANNEL_ID}"/>
      <author>
        <name>Provider channel</name>
        <uri>https://www.youtube.com/channel/${CHANNEL_ID}</uri>
      </author>
      <published>2026-07-24T00:00:00+00:00</published>
      ${Array.from(
        { length: entryCount },
        (_, index) => realisticEntry(index),
      ).join("")}
    </feed>`);
}

function assertAtomError(
  callback: () => unknown,
  code: YouTubeWebSubAtomError["code"],
): void {
  assert.throws(callback, (error: unknown) => {
    assert.ok(error instanceof YouTubeWebSubAtomError);
    assert.equal(error.code, code);
    return true;
  });
}

test("parses the official YouTube Atom entry into an idempotent hint", () => {
  const result = parseYouTubeWebSubAtomFeed(feed(), CHANNEL_ID);
  assert.equal(result.channelId, CHANNEL_ID);
  assert.equal(result.feedUpdatedAt, "2026-07-24T00:02:00Z");
  assert.equal(result.events.length, 1);
  assert.deepEqual(result.events[0], {
    kind: "UPSERT_CANDIDATE",
    eventKey: result.events[0]?.eventKey,
    channelId: CHANNEL_ID,
    videoId: VIDEO_ID,
    entryId: `yt:video:${VIDEO_ID}`,
    publishedAt: "2026-07-24T00:00:00Z",
    updatedAt: "2026-07-24T00:01:00Z",
  });
  assert.match(result.events[0]?.eventKey ?? "", /^[a-f0-9]{64}$/u);
});

test("parses the exact documented YouTube notification shape", () => {
  const result = parseYouTubeWebSubAtomFeed(
    officialDocumentedFeedFixture(),
    CHANNEL_ID,
  );
  assert.equal(result.feedUpdatedAt, "2015-04-01T19:05:24.552394234Z");
  assert.deepEqual(result.events[0], {
    kind: "UPSERT_CANDIDATE",
    eventKey: result.events[0]?.eventKey,
    channelId: CHANNEL_ID,
    videoId: VIDEO_ID,
    entryId: `yt:video:${VIDEO_ID}`,
    publishedAt: "2015-03-06T21:40:57Z",
    updatedAt: "2015-03-09T19:05:24.552394234Z",
  });
});

test("accepts only the documented and live YouTube self identities", () => {
  for (const protocol of ["https", "http"]) {
    for (const selfPath of [
      "/feeds/videos.xml",
      "/xml/feeds/videos.xml",
    ]) {
      const payload = bytes(`
        <feed xmlns="${ATOM_NAMESPACE}" xmlns:yt="${YOUTUBE_NAMESPACE}">
          <link rel="hub" href="https://pubsubhubbub.appspot.com"/>
          <link rel="self"
            href="${protocol}://www.youtube.com${selfPath}?channel_id=${CHANNEL_ID}"/>
          ${entry()}
        </feed>`);
      assert.equal(
        parseYouTubeWebSubAtomFeed(payload, CHANNEL_ID).events.length,
        1,
      );
    }
  }
});

test("supports namespace-prefixed Atom without trusting tag spelling alone", () => {
  const payload = bytes(`
    <atom:feed xmlns:atom="${ATOM_NAMESPACE}"
      xmlns:yt="${YOUTUBE_NAMESPACE}">
      <atom:updated>2026-07-24T00:02:00Z</atom:updated>
      <atom:entry>
        <atom:id>yt:video:${VIDEO_ID}</atom:id>
        <yt:videoId>${VIDEO_ID}</yt:videoId>
        <yt:channelId>${CHANNEL_ID}</yt:channelId>
        <atom:updated>2026-07-24T00:01:00Z</atom:updated>
      </atom:entry>
    </atom:feed>`);
  const result = parseYouTubeWebSubAtomFeed(payload, CHANNEL_ID);
  assert.equal(result.events[0]?.videoId, VIDEO_ID);
});

test("deduplicates identical events and preserves distinct provider updates", () => {
  const duplicate = entry();
  const result = parseYouTubeWebSubAtomFeed(
    feed(
      duplicate +
        duplicate +
        entry(VIDEO_ID, CHANNEL_ID, "2026-07-24T00:01:01Z"),
    ),
    CHANNEL_ID,
  );
  assert.equal(result.events.length, 2);
  assert.notEqual(
    result.events[0]?.eventKey,
    result.events[1]?.eventKey,
  );
});

test("canonicalizes equivalent provider timestamps and event keys", () => {
  const timestamps = [
    "2026-07-24T00:01:00Z",
    "2026-07-24T05:31:00+05:30",
    "2026-07-24T00:01:00.000000000Z",
  ];
  const results = timestamps.map((timestamp) =>
    parseYouTubeWebSubAtomFeed(
      feed(entry(VIDEO_ID, CHANNEL_ID, timestamp)),
      CHANNEL_ID,
    ).events[0],
  );
  assert.deepEqual(
    results.map((result) =>
      result?.kind === "UPSERT_CANDIDATE"
        ? result.updatedAt
        : undefined,
    ),
    [
      "2026-07-24T00:01:00Z",
      "2026-07-24T00:01:00Z",
      "2026-07-24T00:01:00Z",
    ],
  );
  assert.equal(results[0]?.eventKey, results[1]?.eventKey);
  assert.equal(results[0]?.eventKey, results[2]?.eventKey);
});

test("strictly rejects impossible RFC 3339 calendar and time fields", () => {
  for (const timestamp of [
    "2026-02-29T00:00:00Z",
    "2024-02-30T00:00:00Z",
    "2026-13-01T00:00:00Z",
    "2026-01-01T24:00:00Z",
    "2026-01-01T00:60:00Z",
    "2026-01-01T00:00:60Z",
    "2026-01-01T00:00:00+24:00",
    "2026-01-01T00:00:00+05:60",
  ]) {
    assertAtomError(
      () =>
        parseYouTubeWebSubAtomFeed(
          feed(entry(VIDEO_ID, CHANNEL_ID, timestamp)),
          CHANNEL_ID,
        ),
      "invalid_timestamp",
    );
  }
  const validLeapDay = parseYouTubeWebSubAtomFeed(
    feed(
      entry(
        VIDEO_ID,
        CHANNEL_ID,
        "2024-02-29T23:59:59.123400000+05:30",
      ),
    ),
    CHANNEL_ID,
  );
  assert.equal(
    validLeapDay.events[0]?.kind === "UPSERT_CANDIDATE"
      ? validLeapDay.events[0].updatedAt
      : undefined,
    "2024-02-29T18:29:59.1234Z",
  );
});

test("parses RFC 6721 tombstones only as origin-checked delete hints", () => {
  const tombstone = `
    <at:deleted-entry ref="yt:video:${VIDEO_ID}"
      when="2026-07-24T00:03:00Z"/>`;
  const result = parseYouTubeWebSubAtomFeed(
    feed(tombstone),
    CHANNEL_ID,
  );
  assert.deepEqual(result.events[0], {
    kind: "DELETE_HINT",
    eventKey: result.events[0]?.eventKey,
    channelId: CHANNEL_ID,
    videoId: VIDEO_ID,
    entryId: `yt:video:${VIDEO_ID}`,
    deletedAt: "2026-07-24T00:03:00Z",
    requiresExistingSnapshotOriginCheck: true,
  });
});

test("does not invent deletion semantics for malformed tombstones", () => {
  assertAtomError(
    () =>
      parseYouTubeWebSubAtomFeed(
        feed(
          `<at:deleted-entry ref="https://evil.example/video"
            when="2026-07-24T00:03:00Z"/>`,
        ),
        CHANNEL_ID,
      ),
    "invalid_identifier",
  );
  assertAtomError(
    () =>
      parseYouTubeWebSubAtomFeed(
        feed(
          `<at:deleted-entry ref="yt:video:${VIDEO_ID}"
            when="not-a-date"/>`,
        ),
        CHANNEL_ID,
      ),
    "invalid_timestamp",
  );
});

test("rejects channel, video and Atom ID mismatches", () => {
  assertAtomError(
    () =>
      parseYouTubeWebSubAtomFeed(
        feed(entry(VIDEO_ID, OTHER_CHANNEL_ID)),
        CHANNEL_ID,
      ),
    "channel_mismatch",
  );
  assertAtomError(
    () =>
      parseYouTubeWebSubAtomFeed(
        feed(entry("invalid")),
        CHANNEL_ID,
      ),
    "invalid_identifier",
  );
  assertAtomError(
    () =>
      parseYouTubeWebSubAtomFeed(
        feed(`
          <entry>
            <id>yt:video:${SECOND_VIDEO_ID}</id>
            <yt:videoId>${VIDEO_ID}</yt:videoId>
            <yt:channelId>${CHANNEL_ID}</yt:channelId>
            <updated>2026-07-24T00:01:00Z</updated>
          </entry>`),
        CHANNEL_ID,
      ),
    "invalid_identifier",
  );
});

test("rejects duplicate identity elements rather than choosing one", () => {
  assertAtomError(
    () =>
      parseYouTubeWebSubAtomFeed(
        feed(`
          <entry>
            <id>yt:video:${VIDEO_ID}</id>
            <yt:videoId>${VIDEO_ID}</yt:videoId>
            <yt:videoId>${SECOND_VIDEO_ID}</yt:videoId>
            <yt:channelId>${CHANNEL_ID}</yt:channelId>
            <updated>2026-07-24T00:01:00Z</updated>
          </entry>`),
        CHANNEL_ID,
      ),
    "invalid_atom",
  );
});

test("rejects spoofed hub and self links without following them", () => {
  const wrongHub = bytes(`
    <feed xmlns="${ATOM_NAMESPACE}" xmlns:yt="${YOUTUBE_NAMESPACE}">
      <link rel="hub" href="https://evil.example/hub"/>
      ${entry()}
    </feed>`);
  assertAtomError(
    () => parseYouTubeWebSubAtomFeed(wrongHub, CHANNEL_ID),
    "invalid_atom",
  );

  for (const href of [
    `ftp://www.youtube.com/feeds/videos.xml?channel_id=${CHANNEL_ID}`,
    `https://youtube.com/feeds/videos.xml?channel_id=${CHANNEL_ID}`,
    `https://www.youtube.com/watch?v=${VIDEO_ID}`,
    `https://www.youtube.com/feeds/videos.xml?channel_id=${OTHER_CHANNEL_ID}`,
    `https://www.youtube.com/feeds/videos.xml?channel_id=${CHANNEL_ID}&next=bad`,
    `https://user@www.youtube.com/feeds/videos.xml?channel_id=${CHANNEL_ID}`,
  ]) {
    const payload = bytes(`
      <feed xmlns="${ATOM_NAMESPACE}" xmlns:yt="${YOUTUBE_NAMESPACE}">
        <link rel="self" href="${href.replaceAll("&", "&amp;")}"/>
        ${entry()}
      </feed>`);
    assertAtomError(
      () => parseYouTubeWebSubAtomFeed(payload, CHANNEL_ID),
      "invalid_atom",
    );
  }
});

test("parses realistic full feeds within coherent event and element caps", () => {
  const currentSized = realisticFullFeedFixture();
  const currentResult = parseYouTubeWebSubAtomFeed(
    currentSized,
    CHANNEL_ID,
  );
  assert.equal(currentResult.events.length, 15);
  assert.ok(
    currentSized.byteLength <
      DEFAULT_YOUTUBE_WEBSUB_ATOM_LIMITS.maxRawBodyBytes,
  );

  const maximum = parseYouTubeWebSubAtomFeed(
    realisticFullFeedFixture(
      DEFAULT_YOUTUBE_WEBSUB_ATOM_LIMITS.maxEntries,
    ),
    CHANNEL_ID,
  );
  assert.equal(
    maximum.events.length,
    DEFAULT_YOUTUBE_WEBSUB_ATOM_LIMITS.maxEntries,
  );
  assertAtomError(
    () =>
      parseYouTubeWebSubAtomFeed(
        realisticFullFeedFixture(
          DEFAULT_YOUTUBE_WEBSUB_ATOM_LIMITS.maxEntries + 1,
        ),
        CHANNEL_ID,
      ),
    "entry_limit_exceeded",
  );
});

test("rejects DTDs, entity declarations and processing instructions", () => {
  for (const payload of [
    `<!DOCTYPE feed [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
      <feed xmlns="${ATOM_NAMESPACE}">&xxe;</feed>`,
    `<!ENTITY x "unsafe">
      <feed xmlns="${ATOM_NAMESPACE}"></feed>`,
    `<?xml-stylesheet href="https://evil.example/x"?>
      <feed xmlns="${ATOM_NAMESPACE}"></feed>`,
  ]) {
    assertAtomError(
      () => parseYouTubeWebSubAtomFeed(bytes(payload), CHANNEL_ID),
      "unsafe_xml",
    );
  }
});

test("rejects unknown entities but safely decodes predefined and numeric text", () => {
  const safe = feed(
    entry().replace(
      "Safe &amp; current title",
      "Safe &#38; &#x63;urrent title",
    ),
  );
  assert.equal(
    parseYouTubeWebSubAtomFeed(safe, CHANNEL_ID).events.length,
    1,
  );
  assertAtomError(
    () =>
      parseYouTubeWebSubAtomFeed(
        feed(entry().replace("Safe &amp;", "Safe &custom;")),
        CHANNEL_ID,
      ),
    "unsafe_xml",
  );
});

test("rejects malformed, unbound and non-Atom XML", () => {
  const cases: Array<{
    readonly payload: string;
    readonly code: YouTubeWebSubAtomError["code"];
  }> = [
    {
      payload: `<feed xmlns="${ATOM_NAMESPACE}"><entry></feed>`,
      code: "invalid_xml",
    },
    {
      payload: `<feed xmlns="${ATOM_NAMESPACE}"><yt:videoId>${VIDEO_ID}</yt:videoId></feed>`,
      code: "invalid_namespace",
    },
    {
      payload: "<feed></feed>",
      code: "invalid_namespace",
    },
    {
      payload: `<feed xmlns="${ATOM_NAMESPACE}"></feed><feed xmlns="${ATOM_NAMESPACE}"></feed>`,
      code: "invalid_xml",
    },
  ];
  for (const item of cases) {
    assertAtomError(
      () =>
        parseYouTubeWebSubAtomFeed(
          bytes(item.payload),
          CHANNEL_ID,
        ),
      item.code,
    );
  }
});

test("allows harmless comments and CDATA without parsing embedded fake tags", () => {
  const payload = feed(`
    <!-- <entry><yt:videoId>${SECOND_VIDEO_ID}</yt:videoId></entry> -->
    <title><![CDATA[<entry>not an event</entry>]]></title>
    ${entry()}`);
  const result = parseYouTubeWebSubAtomFeed(payload, CHANNEL_ID);
  assert.equal(result.events.length, 1);
  assert.equal(result.events[0]?.videoId, VIDEO_ID);
});

test("enforces event, element, depth, text, attribute and byte limits", () => {
  assertAtomError(
    () =>
      parseYouTubeWebSubAtomFeed(
        feed(entry() + entry(SECOND_VIDEO_ID)),
        CHANNEL_ID,
        { maxEntries: 1 },
      ),
    "entry_limit_exceeded",
  );
  assertAtomError(
    () =>
      parseYouTubeWebSubAtomFeed(feed(), CHANNEL_ID, {
        maxElements: 2,
      }),
    "resource_limit_exceeded",
  );
  assertAtomError(
    () =>
      parseYouTubeWebSubAtomFeed(
        bytes(
          `<feed xmlns="${ATOM_NAMESPACE}"><a><b><c/></b></a></feed>`,
        ),
        CHANNEL_ID,
        { maxDepth: 3 },
      ),
    "resource_limit_exceeded",
  );
  assertAtomError(
    () =>
      parseYouTubeWebSubAtomFeed(
        bytes(
          `<feed xmlns="${ATOM_NAMESPACE}"><title>${"x".repeat(11)}</title></feed>`,
        ),
        CHANNEL_ID,
        { maxTextCharacters: 10 },
      ),
    "resource_limit_exceeded",
  );
  assertAtomError(
    () =>
      parseYouTubeWebSubAtomFeed(
        bytes(
          `<feed xmlns="${ATOM_NAMESPACE}" a="1" b="2"></feed>`,
        ),
        CHANNEL_ID,
        { maxAttributesPerElement: 2 },
      ),
    "resource_limit_exceeded",
  );
  const rawBodyLimit = feed().byteLength - 1;
  assertAtomError(
    () =>
      parseYouTubeWebSubAtomFeed(feed(), CHANNEL_ID, {
        maxRawBodyBytes: rawBodyLimit,
      }),
    "body_too_large",
  );
});

test("rejects invalid UTF-8 and limits may not exceed hard ceilings", () => {
  assertAtomError(
    () =>
      parseYouTubeWebSubAtomFeed(
        Buffer.from([0xc3, 0x28]),
        CHANNEL_ID,
      ),
    "invalid_xml",
  );
  assertAtomError(
    () =>
      parseYouTubeWebSubAtomFeed(
        bytes(
          `<feed xmlns="${ATOM_NAMESPACE}"><title>bad\u0000text</title></feed>`,
        ),
        CHANNEL_ID,
      ),
    "invalid_xml",
  );
  assert.throws(
    () =>
      parseYouTubeWebSubAtomFeed(feed(), CHANNEL_ID, {
        maxEntries:
          DEFAULT_YOUTUBE_WEBSUB_ATOM_LIMITS.maxEntries + 1,
      }),
    /no greater than/u,
  );
});

test("accepts an empty signed feed as a no-op rather than inventing content", () => {
  const result = parseYouTubeWebSubAtomFeed(
    bytes(`<feed xmlns="${ATOM_NAMESPACE}"></feed>`),
    CHANNEL_ID,
  );
  assert.deepEqual(result, { channelId: CHANNEL_ID, events: [] });
});
