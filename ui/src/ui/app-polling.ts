import type { OPENAEONApp } from "./app.ts";
import { loadDebug } from "./controllers/debug.ts";
import { loadAeonLogic } from "./controllers/aeon.ts";
import { loadLogs } from "./controllers/logs.ts";
import { loadNodes } from "./controllers/nodes.ts";
import { loadSandboxTaskPlan } from "./controllers/sandbox.ts";

type PollingHost = {
  nodesPollInterval: number | null;
  logsPollInterval: number | null;
  debugPollInterval: number | null;
  aeonPollInterval: number | null;
  sandboxPollTimer: number | null;
  tab: string;
};

export function startNodesPolling(host: PollingHost) {
  if (host.nodesPollInterval != null) {
    return;
  }
  host.nodesPollInterval = window.setInterval(
    () => void loadNodes(host as unknown as OPENAEONApp, { quiet: true }),
    5000,
  );
}

export function stopNodesPolling(host: PollingHost) {
  if (host.nodesPollInterval == null) {
    return;
  }
  clearInterval(host.nodesPollInterval);
  host.nodesPollInterval = null;
}

export function startLogsPolling(host: PollingHost) {
  if (host.logsPollInterval != null) {
    return;
  }
  host.logsPollInterval = window.setInterval(() => {
    if (host.tab !== "logs") {
      return;
    }
    void loadLogs(host as unknown as OPENAEONApp, { quiet: true });
  }, 2000);
}

export function stopLogsPolling(host: PollingHost) {
  if (host.logsPollInterval == null) {
    return;
  }
  clearInterval(host.logsPollInterval);
  host.logsPollInterval = null;
}

export function startDebugPolling(host: PollingHost) {
  if (host.debugPollInterval != null) {
    return;
  }
  host.debugPollInterval = window.setInterval(() => {
    if (host.tab !== "debug") {
      return;
    }
    void loadDebug(host as unknown as OPENAEONApp);
  }, 3000);
}

export function stopDebugPolling(host: PollingHost) {
  if (host.debugPollInterval == null) {
    return;
  }
  clearInterval(host.debugPollInterval);
  host.debugPollInterval = null;
}

export function startSandboxPolling(host: PollingHost & { sessionKey: string }) {
  if (host.sandboxPollTimer != null) {
    return;
  }
  host.sandboxPollTimer = window.setInterval(() => {
    if (host.tab !== "chat") {
      return;
    }
    void loadSandboxTaskPlan(host as unknown as OPENAEONApp);
  }, 2000);
}

export function stopSandboxPolling(host: PollingHost) {
  if (host.sandboxPollTimer == null) {
    return;
  }
  clearInterval(host.sandboxPollTimer);
  host.sandboxPollTimer = null;
}

export function startAeonPolling(host: PollingHost) {
  if (host.aeonPollInterval != null) {
    return;
  }
  host.aeonPollInterval = window.setInterval(() => {
    if (host.tab !== "aeon") {
      return;
    }
    void loadAeonLogic(host as unknown as OPENAEONApp);
  }, 5000);
}

export function stopAeonPolling(host: PollingHost) {
  if (host.aeonPollInterval == null) {
    return;
  }
  clearInterval(host.aeonPollInterval);
  host.aeonPollInterval = null;
}
