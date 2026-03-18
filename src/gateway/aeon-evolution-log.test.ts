import path from "node:path";
import { beforeEach, describe, expect, it, vi } from "vitest";

const { appendFileMock, mkdirMock } = vi.hoisted(() => ({
  appendFileMock: vi.fn(),
  mkdirMock: vi.fn(),
}));

vi.mock("node:fs/promises", () => ({
  default: {
    appendFile: appendFileMock,
    mkdir: mkdirMock,
  },
}));

vi.mock("../config/paths.js", () => ({
  resolveStateDir: () => "/tmp/openaeon-state",
}));

import { logEvolutionDecisionEvent, logEvolutionEvent } from "./aeon-evolution-log.js";

describe("logEvolutionEvent", () => {
  beforeEach(() => {
    appendFileMock.mockReset();
    mkdirMock.mockReset();
    mkdirMock.mockResolvedValue(undefined);
  });

  it("falls back to state-dir log when repo log path is not writable", async () => {
    appendFileMock.mockRejectedValueOnce(new Error("EPERM"));
    appendFileMock.mockResolvedValueOnce(undefined);
    const warnSpy = vi.spyOn(console, "warn").mockImplementation(() => {});
    const errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});

    await logEvolutionEvent("SYSTEM_MAINTENANCE", "test event", ["first detail"]);

    expect(appendFileMock).toHaveBeenCalledTimes(2);
    const fallbackPath = path.join("/tmp/openaeon-state", "logs", "aeon", "EVOLUTION.md");
    expect(appendFileMock.mock.calls[1]?.[0]).toBe(fallbackPath);
    expect(warnSpy).toHaveBeenCalledTimes(1);
    expect(errorSpy).not.toHaveBeenCalled();

    warnSpy.mockRestore();
    errorSpy.mockRestore();
  });

  it("serializes structured policy decision details", async () => {
    appendFileMock.mockResolvedValueOnce(undefined);

    await logEvolutionDecisionEvent({
      type: "AUTONOMOUS",
      title: "Maintenance Policy Decision",
      policyId: "AEON_MAINTENANCE_GUARDRAIL_V1",
      decision: "BLOCK",
      reasonCode: "MINIMUM_NOT_READY",
      inputs: {
        epiphanyFactor: 0.3,
        memorySaturation: 82,
        idleTimeMs: 1234,
        resonanceTrigger: false,
      },
      thresholds: { redlineBreachRisk: 0.65, minimumReady: true },
      actionTaken: "downgrade:high->low",
      rollbackHint: "set soft mode",
      scopeKey: "session:main|agent:main",
    });

    const entry = String(appendFileMock.mock.calls[0]?.[1] ?? "");
    expect(entry).toContain("Policy ID: AEON_MAINTENANCE_GUARDRAIL_V1");
    expect(entry).toContain("Decision: BLOCK");
    expect(entry).toContain("Reason Code: MINIMUM_NOT_READY");
    expect(entry).toContain("Action Taken: downgrade:high->low");
  });
});
