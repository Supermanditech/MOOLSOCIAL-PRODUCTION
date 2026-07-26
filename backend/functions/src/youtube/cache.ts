export interface CacheClock {
  now(): number;
}

export class SystemCacheClock implements CacheClock {
  now(): number {
    return Date.now();
  }
}

interface CacheEntry<V> {
  readonly value: V;
  readonly expiresAt: number;
}

interface InFlightEntry<V> {
  readonly generation: number;
  readonly promise: Promise<V>;
}

export interface AsyncTtlCacheOptions {
  readonly clock?: CacheClock;
}

/**
 * Small process-local cache for permitted non-personal provider data.
 *
 * Concurrent misses for the same key share one loader promise. Values are
 * cached only after a successful load, and invalidation during a load prevents
 * the stale result from being written back.
 */
export class AsyncTtlCache<K, V> {
  private readonly clock: CacheClock;
  private readonly values = new Map<K, CacheEntry<V>>();
  private readonly inFlight = new Map<K, InFlightEntry<V>>();
  private readonly generations = new Map<K, number>();

  constructor(options: AsyncTtlCacheOptions = {}) {
    this.clock = options.clock ?? new SystemCacheClock();
  }

  get(key: K): V | undefined {
    const entry = this.values.get(key);
    if (entry === undefined) {
      return undefined;
    }
    if (entry.expiresAt <= this.clock.now()) {
      this.values.delete(key);
      return undefined;
    }
    return entry.value;
  }

  set(key: K, value: V, ttlMs: number): void {
    this.assertTtl(ttlMs);
    this.bumpGeneration(key);
    this.inFlight.delete(key);
    if (ttlMs === 0) {
      this.values.delete(key);
      return;
    }
    this.values.set(key, {
      value,
      expiresAt: this.clock.now() + ttlMs,
    });
  }

  async getOrLoad(
    key: K,
    ttlMs: number,
    loader: () => Promise<V> | V,
  ): Promise<V> {
    this.assertTtl(ttlMs);

    const cached = this.get(key);
    if (cached !== undefined) {
      return cached;
    }

    const active = this.inFlight.get(key);
    if (active !== undefined) {
      return active.promise;
    }

    const generation = this.currentGeneration(key);
    let promise!: Promise<V>;
    promise = Promise.resolve()
      .then(loader)
      .then((value) => {
        if (this.currentGeneration(key) === generation && ttlMs > 0) {
          this.values.set(key, {
            value,
            expiresAt: this.clock.now() + ttlMs,
          });
        }
        return value;
      })
      .finally(() => {
        if (this.inFlight.get(key)?.promise === promise) {
          this.inFlight.delete(key);
        }
      });

    this.inFlight.set(key, { generation, promise });
    return promise;
  }

  delete(key: K): boolean {
    const existed = this.values.delete(key) || this.inFlight.has(key);
    this.inFlight.delete(key);
    this.bumpGeneration(key);
    return existed;
  }

  clear(): void {
    const keys = new Set<K>([
      ...this.values.keys(),
      ...this.inFlight.keys(),
    ]);
    for (const key of keys) {
      this.bumpGeneration(key);
    }
    this.values.clear();
    this.inFlight.clear();
  }

  pruneExpired(): number {
    const now = this.clock.now();
    let removed = 0;
    for (const [key, entry] of this.values) {
      if (entry.expiresAt <= now) {
        this.values.delete(key);
        removed += 1;
      }
    }
    return removed;
  }

  private assertTtl(ttlMs: number): void {
    if (!Number.isSafeInteger(ttlMs) || ttlMs < 0) {
      throw new TypeError(
        "Cache TTL must be a non-negative safe integer in milliseconds.",
      );
    }
  }

  private currentGeneration(key: K): number {
    return this.generations.get(key) ?? 0;
  }

  private bumpGeneration(key: K): void {
    this.generations.set(key, this.currentGeneration(key) + 1);
  }
}
