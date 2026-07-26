#!/usr/bin/env node

/**
 * Read-only drift gate for MoolSocial's official YouTube API capability registry.
 *
 * This script:
 * - reads one local registry JSON file;
 * - fetches only the three allowlisted public Google Discovery documents;
 * - sends no credentials, API keys, OAuth tokens, cookies, or mutation requests;
 * - fails when a Discovery revision or method inventory drifts;
 * - never enables a service and never calls a customer/provider data endpoint.
 */

import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const repositoryRoot = path.resolve(scriptDirectory, '..');
const registryPath = path.join(
  repositoryRoot,
  'deployment',
  'youtube-official-api-capability-registry',
  'capability-registry.json',
);

const providerOperationSourcePaths = [
  path.join(repositoryRoot, 'backend', 'functions', 'src', 'index.ts'),
  path.join(
    repositoryRoot,
    'backend',
    'functions',
    'src',
    'youtube',
    'provider_service.ts',
  ),
  path.join(
    repositoryRoot,
    'backend',
    'functions',
    'src',
    'youtube',
    'owner_client.ts',
  ),
];

const allowedDiscoveryUrls = new Set([
  'https://www.googleapis.com/discovery/v1/apis/youtube/v3/rest',
  'https://www.googleapis.com/discovery/v1/apis/youtubeAnalytics/v2/rest',
  'https://www.googleapis.com/discovery/v1/apis/youtubereporting/v1/rest',
]);

const allowedAvailabilityClasses = new Set([
  'implemented-local',
  'disabled-gated',
  'eligibility/partner-only',
  'unsupported-customer-value',
  'deprecated/excluded',
]);

const allowedProductPhases = new Set([
  'A-private-dev-proof',
  'B-public-read-plane',
  'C-connected-viewer-actions',
  'D-creator-channel-management',
  'E-creator-live-workspace',
  'F-creator-intelligence-reporting',
  'G-provider-granted-only',
  'permanent-exclusion',
]);

const allowedScopeClasses = new Set([
  'public-api-key',
  'owner-readonly',
  'owner-force-ssl-write',
  'owner-upload',
  'owner-live-readonly',
  'owner-live-write',
  'membership-creator',
  'analytics-readonly',
  'analytics-or-monetary-readonly',
  'reporting-or-monetary-readonly',
  'provider-granted-linking-token',
  'no-auth-public',
  'excluded-readonly-test',
  'partner-or-owner-write',
]);

function invariant(condition, message, errors) {
  if (!condition) {
    errors.push(message);
  }
}

function sortedUnique(values) {
  return [...new Set(values)].sort((left, right) => left.localeCompare(right));
}

function enumerateDiscoveryMethods(document) {
  const methods = [];

  function visit(resources, resourcePath = []) {
    for (const [resourceName, resource] of Object.entries(resources ?? {})) {
      const nextPath = [...resourcePath, resourceName];
      for (const [methodName, method] of Object.entries(resource.methods ?? {})) {
        methods.push({
          discoveryMethodId: method.id,
          resourcePath: nextPath.join('.'),
          methodName,
          httpMethod: method.httpMethod,
          scopes: sortedUnique(method.scopes ?? []),
        });
      }
      visit(resource.resources, nextPath);
    }
  }

  for (const [methodName, method] of Object.entries(document.methods ?? {})) {
    methods.push({
      discoveryMethodId: method.id,
      resourcePath: '',
      methodName,
      httpMethod: method.httpMethod,
      scopes: sortedUnique(method.scopes ?? []),
    });
  }
  visit(document.resources);

  return methods.sort((left, right) =>
    left.discoveryMethodId.localeCompare(right.discoveryMethodId),
  );
}

async function fetchDiscoveryDocument(url) {
  if (!allowedDiscoveryUrls.has(url)) {
    throw new Error(`Discovery URL is not allowlisted: ${url}`);
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 20_000);
  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        accept: 'application/json',
        'user-agent': 'moolsocial-read-only-youtube-discovery-drift-gate/1.0',
      },
      redirect: 'error',
      signal: controller.signal,
    });
    if (!response.ok) {
      throw new Error(`Discovery fetch failed (${response.status}) for ${url}`);
    }
    return await response.json();
  } finally {
    clearTimeout(timeout);
  }
}

function validateRegistryShape(registry) {
  const errors = [];
  invariant(registry?.schemaVersion === 1, 'schemaVersion must be 1.', errors);
  invariant(
    typeof registry?.authority?.existingAudit === 'string' &&
      registry.authority.existingAudit.length > 0,
    'authority.existingAudit must be populated.',
    errors,
  );
  invariant(
    Array.isArray(registry?.sources) && registry.sources.length === 3,
    'Registry must contain exactly three Discovery sources.',
    errors,
  );

  const sourceKeys = new Set();
  const allMethodIds = new Set();
  for (const source of registry?.sources ?? []) {
    invariant(
      typeof source.key === 'string' && source.key.length > 0,
      'Each source must have a key.',
      errors,
    );
    invariant(!sourceKeys.has(source.key), `Duplicate source key: ${source.key}`, errors);
    sourceKeys.add(source.key);
    invariant(
      allowedDiscoveryUrls.has(source.discoveryUrl),
      `Source ${source.key} uses a non-allowlisted Discovery URL.`,
      errors,
    );
    invariant(
      typeof source.discoveryRevision === 'string' &&
        /^\d{8}$/.test(source.discoveryRevision),
      `Source ${source.key} has an invalid discoveryRevision.`,
      errors,
    );
    invariant(
      Number.isInteger(source.expectedMethodCount) && source.expectedMethodCount > 0,
      `Source ${source.key} has an invalid expectedMethodCount.`,
      errors,
    );
    invariant(
      Array.isArray(source.methods),
      `Source ${source.key} methods must be an array.`,
      errors,
    );
    invariant(
      source.methods?.length === source.expectedMethodCount,
      `Source ${source.key} expectedMethodCount does not match registry entries.`,
      errors,
    );

    const localMethodIds = new Set();
    for (const capability of source.methods ?? []) {
      const id = capability.discoveryMethodId;
      invariant(
        typeof id === 'string' && id.length > 0,
        `Source ${source.key} contains a method without discoveryMethodId.`,
        errors,
      );
      invariant(!localMethodIds.has(id), `Duplicate method in ${source.key}: ${id}`, errors);
      invariant(!allMethodIds.has(id), `Method appears in multiple sources: ${id}`, errors);
      localMethodIds.add(id);
      allMethodIds.add(id);
      invariant(
        capability.discoveryRevision === source.discoveryRevision,
        `${id} discoveryRevision must equal its source revision.`,
        errors,
      );
      invariant(
        typeof capability.capabilityMethod === 'string' &&
          capability.capabilityMethod.length > 0,
        `${id} must have capabilityMethod.`,
        errors,
      );
      invariant(
        allowedProductPhases.has(capability.productPhase),
        `${id} has unknown productPhase: ${capability.productPhase}`,
        errors,
      );
      invariant(
        allowedAvailabilityClasses.has(capability.availabilityClass),
        `${id} has unknown availabilityClass: ${capability.availabilityClass}`,
        errors,
      );
      invariant(
        allowedScopeClasses.has(capability.scopeClass),
        `${id} has unknown scopeClass: ${capability.scopeClass}`,
        errors,
      );
      invariant(
        typeof capability.reason === 'string' && capability.reason.trim().length >= 24,
        `${id} must have a precise reason of at least 24 characters.`,
        errors,
      );
    }
  }

  return errors;
}

async function validateRemovedCommentSpamCapability(registry) {
  const errors = [];
  const dataApiSource = registry.sources?.find(
    (source) => source.key === 'youtube-data-live-v3',
  );
  const markAsSpam = dataApiSource?.methods?.find(
    (capability) =>
      capability.discoveryMethodId === 'youtube.comments.markAsSpam',
  );
  const setModerationStatus = dataApiSource?.methods?.find(
    (capability) =>
      capability.discoveryMethodId ===
      'youtube.comments.setModerationStatus',
  );

  invariant(
    markAsSpam?.productPhase === 'permanent-exclusion',
    'youtube.comments.markAsSpam must remain a permanent exclusion.',
    errors,
  );
  invariant(
    markAsSpam?.availabilityClass === 'deprecated/excluded',
    'youtube.comments.markAsSpam must remain deprecated/excluded.',
    errors,
  );
  invariant(
    typeof markAsSpam?.reason === 'string' &&
      markAsSpam.reason.includes('no longer supported') &&
      markAsSpam.reason.includes('must not alias'),
    'youtube.comments.markAsSpam must record the official removal reason and no-alias rule.',
    errors,
  );
  invariant(
    setModerationStatus?.availabilityClass !== 'deprecated/excluded' &&
      setModerationStatus?.productPhase !== 'permanent-exclusion',
    'youtube.comments.setModerationStatus must remain a distinct supported owner-moderation capability.',
    errors,
  );

  const forbiddenProviderTokens = [
    'comments.markAsSpam',
    '/comments/markAsSpam',
    'ownerMarkCommentsAsSpam',
    'ownerMarkCommentAsSpam',
    'markCommentsAsSpam',
    'markCommentAsSpam',
  ];
  for (const sourcePath of providerOperationSourcePaths) {
    const source = await readFile(sourcePath, 'utf8');
    for (const token of forbiddenProviderTokens) {
      invariant(
        !source.includes(token),
        `${path.relative(repositoryRoot, sourcePath)} exports or calls the removed ` +
          `comments.markAsSpam capability via "${token}".`,
        errors,
      );
    }
  }

  const ownerClientSource = await readFile(
    path.join(
      repositoryRoot,
      'backend',
      'functions',
      'src',
      'youtube',
      'owner_client.ts',
    ),
    'utf8',
  );
  invariant(
    ownerClientSource.includes('/comments/setModerationStatus') &&
      ownerClientSource.includes('ownerSetCommentModeration'),
    'The distinct comments.setModerationStatus owner capability must remain implemented.',
    errors,
  );

  return errors;
}

function compareMethodInventories(source, discoveryDocument) {
  const errors = [];
  const discoveredMethods = enumerateDiscoveryMethods(discoveryDocument);
  const registryIds = sortedUnique(
    source.methods.map((capability) => capability.discoveryMethodId),
  );
  const discoveredIds = sortedUnique(
    discoveredMethods.map((method) => method.discoveryMethodId),
  );
  const registrySet = new Set(registryIds);
  const discoveredSet = new Set(discoveredIds);
  const added = discoveredIds.filter((id) => !registrySet.has(id));
  const removed = registryIds.filter((id) => !discoveredSet.has(id));

  invariant(
    discoveredMethods.length === source.expectedMethodCount,
    `${source.key} method-count drift: expected ${source.expectedMethodCount}, ` +
      `official Discovery has ${discoveredMethods.length}.`,
    errors,
  );
  invariant(
    added.length === 0,
    `${source.key} has unclassified added methods: ${added.join(', ')}`,
    errors,
  );
  invariant(
    removed.length === 0,
    `${source.key} has removed methods still classified: ${removed.join(', ')}`,
    errors,
  );

  return { errors, discoveredMethods, added, removed };
}

async function main() {
  const registry = JSON.parse(await readFile(registryPath, 'utf8'));
  const errors = validateRegistryShape(registry);
  errors.push(...(await validateRemovedCommentSpamCapability(registry)));
  let totalMethods = 0;

  for (const source of registry.sources ?? []) {
    const discoveryDocument = await fetchDiscoveryDocument(source.discoveryUrl);
    invariant(
      discoveryDocument.id === source.discoveryId,
      `${source.key} discoveryId drift: expected ${source.discoveryId}, ` +
        `received ${discoveryDocument.id}.`,
      errors,
    );
    invariant(
      discoveryDocument.version === source.discoveryVersion,
      `${source.key} version drift: expected ${source.discoveryVersion}, ` +
        `received ${discoveryDocument.version}.`,
      errors,
    );
    invariant(
      discoveryDocument.revision === source.discoveryRevision,
      `${source.key} revision drift: expected ${source.discoveryRevision}, ` +
        `received ${discoveryDocument.revision}.`,
      errors,
    );

    const comparison = compareMethodInventories(source, discoveryDocument);
    errors.push(...comparison.errors);
    totalMethods += comparison.discoveredMethods.length;

    process.stdout.write(
      `${source.key}: revision ${discoveryDocument.revision}; ` +
        `${comparison.discoveredMethods.length}/${source.expectedMethodCount} methods classified.\n`,
    );
  }

  const expectedTotal = registry.sources.reduce(
    (sum, source) => sum + source.expectedMethodCount,
    0,
  );
  invariant(
    totalMethods === expectedTotal,
    `Total method-count drift: expected ${expectedTotal}, discovered ${totalMethods}.`,
    errors,
  );

  if (errors.length > 0) {
    process.stderr.write('\nYouTube official API capability registry verification FAILED:\n');
    for (const error of errors) {
      process.stderr.write(`- ${error}\n`);
    }
    process.exitCode = 1;
    return;
  }

  process.stdout.write(
    `PASS: ${totalMethods}/${expectedTotal} official methods are classified; ` +
      'all pinned revisions match; no credentials or mutations were used.\n',
  );
}

main().catch((error) => {
  process.stderr.write(`YouTube registry verification failed: ${error.stack ?? error}\n`);
  process.exitCode = 1;
});
