/**
 * Provider id normalization + record lookups.
 * Kept dependency-free so auth-profiles can import without pulling in model-selection.
 */

export function normalizeProviderId(provider: string): string {
  const normalized = provider.trim().toLowerCase();
  if (normalized === "z.ai" || normalized === "z-ai") {
    return "zai";
  }
  if (normalized === "opencode-zen") {
    return "opencode";
  }
  if (normalized === "qwen") {
    return "qwen-portal";
  }
  if (normalized === "kimi-code") {
    return "kimi-coding";
  }
  if (normalized === "bedrock" || normalized === "aws-bedrock") {
    return "amazon-bedrock";
  }
  // Backward compatibility for older provider naming.
  if (normalized === "bytedance" || normalized === "doubao") {
    return "volcengine";
  }
  return normalized;
}

export function findNormalizedProviderValue<T>(
  entries: Record<string, T> | undefined,
  provider: string,
): T | undefined {
  if (!entries) {
    return undefined;
  }
  const providerKey = normalizeProviderId(provider);
  for (const [key, value] of Object.entries(entries)) {
    if (normalizeProviderId(key) === providerKey) {
      return value;
    }
  }
  return undefined;
}

export function findNormalizedProviderKey(
  entries: Record<string, unknown> | undefined,
  provider: string,
): string | undefined {
  if (!entries) {
    return undefined;
  }
  const providerKey = normalizeProviderId(provider);
  return Object.keys(entries).find((key) => normalizeProviderId(key) === providerKey);
}
