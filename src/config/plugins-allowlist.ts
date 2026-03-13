import type { OPENAEONConfig } from "./config.js";

export function ensurePluginAllowlisted(cfg: OPENAEONConfig, pluginId: string): OPENAEONConfig {
  const allow = cfg.plugins?.allow;
  if (!Array.isArray(allow) || allow.includes(pluginId)) {
    return cfg;
  }
  return {
    ...cfg,
    plugins: {
      ...cfg.plugins,
      allow: [...allow, pluginId],
    },
  };
}
