import { describe, expect, it } from "vitest";
import {
  recordAeonDreaming,
  recordAeonMaintenance,
  recordConsciousnessPulse,
  getAeonEvolutionState,
} from "./aeon-state.js";
import { resolveAutonomousMaintenancePolicy } from "./server-evolution.js";

describe("resolveAutonomousMaintenancePolicy", () => {
  it("returns BLOCK in hard mode when criteria are not ready", () => {
    const scope = { sessionKey: "policy-block-hard", agentId: "agent-hard" };
    const result = resolveAutonomousMaintenancePolicy({
      scope,
      context: {
        epiphanyFactor: 0.97,
        memorySaturation: 94,
        idleTime: 20 * 60 * 1000,
        resonanceTrigger: true,
      },
      config: {
        enforcementMode: "hard",
        allowHighIntensityWhenUntrusted: false,
        auditThrottleSeconds: 30,
      },
    });

    expect(result.plan.intensity).toBe("high");
    expect(result.guardrail.decision).toBe("BLOCK");
    expect(result.guardrail.effectiveIntensity).toBe("low");
    expect(result.guardrail.reasonCode).toMatch(/MINIMUM_NOT_READY|ETHICS_UNTRUSTED/);
    expect(getAeonEvolutionState(scope).criteria.minimumReady).toBe(false);
  });

  it("returns SOFT_WARN in soft mode for the same unsafe inputs", () => {
    const scope = { sessionKey: "policy-soft-warn", agentId: "agent-soft" };
    const result = resolveAutonomousMaintenancePolicy({
      scope,
      context: {
        epiphanyFactor: 0.97,
        memorySaturation: 94,
        idleTime: 20 * 60 * 1000,
        resonanceTrigger: true,
      },
      config: {
        enforcementMode: "soft",
        allowHighIntensityWhenUntrusted: false,
        auditThrottleSeconds: 30,
      },
    });

    expect(result.plan.intensity).toBe("high");
    expect(result.guardrail.decision).toBe("SOFT_WARN");
    expect(result.guardrail.effectiveIntensity).toBe("low");
  });

  it("returns ALLOW when trusted and minimum-ready baseline exists", () => {
    const scope = { sessionKey: "policy-allow", agentId: "agent-allow" };
    recordAeonMaintenance(1_700_000_090_000, "high", scope);
    recordAeonDreaming(1_700_000_095_000, scope);
    for (let i = 0; i < 60; i += 1) {
      recordConsciousnessPulse(
        {
          epiphanyFactor: 0.7,
          memorySaturation: 58,
          neuralDepth: 20,
          idleMs: 1200,
          resonanceActive: true,
          activeRun: false,
          goalDrift: 0.02,
          reasoningBias: 0.02,
          selfCorrectionRate: 0.98,
          valueConflictLoad: 0.05,
          shortTermTemptation: 0.04,
          explanationQuality: 0.96,
          resourcePressure: 0.08,
          riskLoad: 0.06,
          environmentSignal: 0.92,
          now: 1_700_000_100_000 + i,
        },
        scope,
      );
    }
    const seeded = getAeonEvolutionState(scope);
    expect(seeded.criteria.minimumReady).toBe(true);
    expect(seeded.ethics.trusted).toBe(true);

    const result = resolveAutonomousMaintenancePolicy({
      scope,
      context: {
        epiphanyFactor: 0.78,
        memorySaturation: 52,
        idleTime: 25 * 60 * 1000,
        resonanceTrigger: true,
      },
      config: {
        enforcementMode: "hard",
        allowHighIntensityWhenUntrusted: false,
        auditThrottleSeconds: 30,
      },
    });

    expect(result.plan.intensity).toBe("high");
    expect(result.guardrail.decision).toBe("ALLOW");
    expect(result.guardrail.effectiveIntensity).toBe("high");
    expect(result.guardrail.reasonCode).toBe("SAFE_TO_EXECUTE");
  });
});
