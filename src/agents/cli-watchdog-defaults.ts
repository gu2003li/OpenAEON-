export const CLI_WATCHDOG_MIN_TIMEOUT_MS = 1_000;

// Fresh runs: long ceiling so installs/downloads (e.g. pnpm install) don't trigger false no-output timeouts.
export const CLI_FRESH_WATCHDOG_DEFAULTS = {
  noOutputTimeoutRatio: 0.8,
  minMs: 180_000,
  maxMs: 900_000,
} as const;

// Resume runs: aligned with fresh so long tool runs (install deps, brew, etc.) don't hit stricter no-output limits.
export const CLI_RESUME_WATCHDOG_DEFAULTS = {
  noOutputTimeoutRatio: 0.8,
  minMs: 180_000,
  maxMs: 900_000,
} as const;
