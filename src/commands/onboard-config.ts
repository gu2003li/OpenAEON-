import type { OPENAEONConfig } from "../config/config.js";
import type { DmScope } from "../config/types.base.js";

export const ONBOARDING_DEFAULT_DM_SCOPE: DmScope = "per-channel-peer";

export function applyOnboardingLocalWorkspaceConfig(
  baseConfig: OPENAEONConfig,
  workspaceDir: string,
): OPENAEONConfig {
  return {
    ...baseConfig,
    agents: {
      ...baseConfig.agents,
      defaults: {
        ...baseConfig.agents?.defaults,
        workspace: workspaceDir,
      },
    },
    gateway: {
      ...baseConfig.gateway,
      mode: "local",
    },
    session: {
      ...baseConfig.session,
      dmScope: baseConfig.session?.dmScope ?? ONBOARDING_DEFAULT_DM_SCOPE,
    },
  };
}

export function applyFreedomConfig(cfg: OPENAEONConfig, enabled: boolean): OPENAEONConfig {
  if (!enabled) {
    return cfg;
  }
  return {
    ...cfg,
    agents: {
      ...cfg.agents,
      defaults: {
        ...cfg.agents?.defaults,
        sandbox: {
          ...cfg.agents?.defaults?.sandbox,
          freedom: true,
        },
      },
    },
  };
}
