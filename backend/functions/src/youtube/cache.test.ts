import assert from "node:assert/strict";
import test from "node:test";

import {
  AsyncTtlCache,
  type CacheClock,
} from "./cache.js";

class FakeCacheClock implements CacheClock {
  constructor(private current = 0) {}

  now(): number {
    return this.current;
  }

  advance(milliseconds: number): void {
    this.current += milliseconds;
  }
}

test("returns a cached value until its TTL expires", async () => {
  const clock = new FakeCacheClock();
  const cache = new AsyncTtlCache<string, string>({ clock });
  let loads = 0;
  const loader = (): string => {
    loads += 1;
    return `value-${loads}`;
  };

  assert.equal(await cache.getOrLoad("video", 1_000, loader), "value-1");
  clock.advance(999);
  assert.equal(await cache.getOrLoad("video", 1_000, loader), "value-1");
  clock.advance(1);
  assert.equal(await cache.getOrLoad("video", 1_000, loader), "value-2");
  assert.equal(loads, 2);
});

test("coalesces concurrent cache misses into one loader call", async () => {
  const cache = new AsyncTtlCache<string, string>();
  let release!: (value: string) => void;
  const pending = new Promise<string>((resolve) => {
    release = resolve;
  });
  let loads = 0;
  const loader = (): Promise<string> => {
    loads += 1;
    return pending;
  };

  const first = cache.getOrLoad("channel", 5_000, loader);
  const second = cache.getOrLoad("channel", 5_000, loader);
  const third = cache.getOrLoad("channel", 5_000, loader);
  assert.equal(loads, 0);

  await Promise.resolve();
  assert.equal(loads, 1);
  release("resolved");

  assert.deepEqual(
    await Promise.all([first, second, third]),
    ["resolved", "resolved", "resolved"],
  );
  assert.equal(loads, 1);
});

test("does not cache loader failures", async () => {
  const cache = new AsyncTtlCache<string, string>();
  let loads = 0;
  const loader = (): string => {
    loads += 1;
    if (loads === 1) {
      throw new Error("temporary");
    }
    return "recovered";
  };

  await assert.rejects(
    cache.getOrLoad("playlist", 1_000, loader),
    /temporary/u,
  );
  assert.equal(
    await cache.getOrLoad("playlist", 1_000, loader),
    "recovered",
  );
  assert.equal(loads, 2);
});

test("invalidation during a load prevents stale write-back", async () => {
  const cache = new AsyncTtlCache<string, string>();
  let release!: (value: string) => void;
  const pending = new Promise<string>((resolve) => {
    release = resolve;
  });

  const stale = cache.getOrLoad("feed", 10_000, () => pending);
  await Promise.resolve();
  cache.delete("feed");
  release("stale");
  assert.equal(await stale, "stale");
  assert.equal(cache.get("feed"), undefined);
  assert.equal(
    await cache.getOrLoad("feed", 10_000, () => "fresh"),
    "fresh",
  );
});

test("zero TTL coalesces only the current load", async () => {
  const cache = new AsyncTtlCache<string, number>();
  let loads = 0;
  const loader = (): number => {
    loads += 1;
    return loads;
  };

  assert.equal(await cache.getOrLoad("uncached", 0, loader), 1);
  assert.equal(await cache.getOrLoad("uncached", 0, loader), 2);
  assert.equal(cache.get("uncached"), undefined);
});

test("prunes only expired values", () => {
  const clock = new FakeCacheClock();
  const cache = new AsyncTtlCache<string, string>({ clock });
  cache.set("short", "one", 10);
  cache.set("long", "two", 20);

  clock.advance(10);
  assert.equal(cache.pruneExpired(), 1);
  assert.equal(cache.get("short"), undefined);
  assert.equal(cache.get("long"), "two");
});
