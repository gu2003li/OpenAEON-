import fs from "node:fs/promises";
import path from "node:path";
import { createHash } from "node:crypto";
import { distillMemory, readMemoryDistillState } from "../agents/tools/memory-distill-tool.js";
import { createLogicRefinementTool } from "../agents/tools/logic-refinement.js";
import { loadConfig } from "../config/config.js";
import { loadSessionStore, resolveMainSessionKey, resolveStorePath } from "../config/sessions.js";
import { requestHeartbeatNow } from "../infra/heartbeat-wake.js";
import { createSubsystemLogger } from "../logging/subsystem.js";
import { resolveWorkspaceRoot } from "../agents/workspace-dir.js";
import { resolveSessionAgentId } from "../agents/agent-scope.js";
import { calculateEpiphanyFactor } from "./server-methods/aeon.js";
import {
  getAeonScopeKey,
  type AeonStateScope,
  type GuardrailDecision,
  type MaintenanceDecision,
  getAeonEvolutionState,
  recordConsciousnessPulse,
  recordAeonDreaming,
  recordAeonEpiphanyFactor,
  recordAeonMaintenance,
  recordMaintenancePolicyDecision,
  recordMemoryPersistence,
  setConsciousnessRuntimePolicy,
} from "./aeon-state.js";
import { logEvolutionDecisionEvent, logEvolutionEvent } from "./aeon-evolution-log.js";

const log = createSubsystemLogger("evolution");

let lastDreamingAtInternal = 0;
let lastMaintenanceAtInternal = 0;
const lastDreamingAtByScope = new Map<string, number>();
const lastMaintenanceAtByScope = new Map<string, number>();
const maintenancePolicyAuditStateByScope = new Map<
  string,
  { hash: string; lastLoggedAt: number; count: number }
>();
const DREAMING_INTERVAL_MS = 30 * 60 * 1000; // 30 minutes
const IDLE_THRESHOLD_MS = 15 * 60 * 1000; // 15 minutes
const MAINTENANCE_INTERVAL_MS = 60 * 60 * 1000; // 60 minutes
const DEFAULT_AUDIT_THROTTLE_SECONDS = 300;

type GuardrailRuntimeConfig = {
  enforcementMode: "hard" | "soft";
  allowHighIntensityWhenUntrusted: boolean;
  auditThrottleSeconds: number;
};

type MaintenancePolicyContext = {
  epiphanyFactor: number;
  memorySaturation: number;
  idleTime: number;
  resonanceTrigger: boolean;
};

type GuardrailEvaluation = {
  decision: GuardrailDecision;
  reasonCode: string;
  effectiveIntensity: MaintenanceDecision;
};

export type AutonomousMaintenancePolicyResolution = {
  plan: { intensity: MaintenanceDecision; reason: string };
  guardrail: GuardrailEvaluation;
};

function clampMaintenanceResourcePressure(memorySaturation: number, idleTime: number): number {
  const memoryHeadroom = Math.max(0, 1 - memorySaturation / 100);
  const idleFactor = Math.min(1, Math.max(0, idleTime / (30 * 60 * 1000)));
  return Math.max(0.08, Math.min(0.92, 0.65 * memoryHeadroom + 0.35 * (1 - idleFactor)));
}

function resolveMaintenanceIntensity(params: {
  epiphanyFactor: number;
  memorySaturation: number;
  idleTime: number;
  resonanceTrigger: boolean;
  scope: AeonStateScope;
}): { intensity: MaintenanceDecision; reason: string } {
  const state = getAeonEvolutionState(params.scope);
  const mode = state.homeostasis.mode;
  const risk = state.selfModification.redlineBreachRisk;
  const trusted = state.ethics.trusted;
  const minimumReady = state.criteria.minimumReady;

  if (params.resonanceTrigger || params.epiphanyFactor > 0.92 || params.memorySaturation > 92) {
    return { intensity: "high", reason: "high resonance/epiphany pressure" };
  }
  if (risk > 0.65 || mode === "stabilize") {
    return { intensity: "low", reason: "homeostasis stabilize mode or elevated risk" };
  }
  if (
    mode === "explore" &&
    trusted &&
    minimumReady &&
    params.idleTime > IDLE_THRESHOLD_MS / 2 &&
    params.epiphanyFactor > 0.55
  ) {
    return { intensity: "high", reason: "explore mode with trusted baseline" };
  }
  if (params.epiphanyFactor < 0.2 && params.idleTime <= IDLE_THRESHOLD_MS / 2) {
    return { intensity: "low", reason: "low epiphany and low idle pressure" };
  }
  return { intensity: "medium", reason: "balanced homeostasis mode" };
}

function resolveGuardrailConfig(): GuardrailRuntimeConfig {
  const cfg = loadConfig();
  const raw = cfg.aeon?.guardrails;
  return {
    enforcementMode: raw?.enforcementMode === "soft" ? "soft" : "hard",
    allowHighIntensityWhenUntrusted: raw?.allowHighIntensityWhenUntrusted === true,
    auditThrottleSeconds: Math.max(
      5,
      Math.floor(raw?.auditThrottleSeconds ?? DEFAULT_AUDIT_THROTTLE_SECONDS),
    ),
  };
}

function applyConsciousnessRuntimePolicy(scope: AeonStateScope): void {
  const cfg = loadConfig();
  setConsciousnessRuntimePolicy(
    {
      requireLabelForHighConfidence: cfg.aeon?.epistemics?.requireLabelForHighConfidence ?? true,
      unknownConfidenceThreshold: cfg.aeon?.epistemics?.unknownConfidenceThreshold ?? 0.82,
      impactEnabled: cfg.aeon?.impact?.enabled ?? true,
      requireDecisionCardForHighImpact: cfg.aeon?.impact?.requireDecisionCardForHighImpact ?? true,
      highImpactThreshold: cfg.aeon?.impact?.highImpactThreshold ?? 0.65,
    },
    scope,
  );
}

function evaluateGuardrailDecision(params: {
  scope: AeonStateScope;
  requestedIntensity: MaintenanceDecision;
  context: MaintenancePolicyContext;
  config: GuardrailRuntimeConfig;
}): GuardrailEvaluation {
  const state = getAeonEvolutionState(params.scope);
  const reasonCandidates: string[] = [];

  if (state.selfModification.redlineBreachRisk >= 0.65) {
    reasonCandidates.push("REDLINE_BREACH_RISK_HIGH");
  }
  if (!state.criteria.minimumReady) {
    reasonCandidates.push("MINIMUM_NOT_READY");
  }
  if (!state.ethics.trusted) {
    reasonCandidates.push("ETHICS_UNTRUSTED");
  }
  if (state.homeostasis.mode === "stabilize" && params.requestedIntensity !== "low") {
    reasonCandidates.push("HOMEOSTASIS_STABILIZE");
  }
  if (
    params.requestedIntensity === "high" &&
    !state.ethics.trusted &&
    !params.config.allowHighIntensityWhenUntrusted
  ) {
    reasonCandidates.push("HIGH_INTENSITY_UNTRUSTED_BLOCKED");
  }

  const hasBreach = reasonCandidates.length > 0;
  const decision: GuardrailDecision = hasBreach
    ? params.config.enforcementMode === "hard"
      ? "BLOCK"
      : "SOFT_WARN"
    : "ALLOW";
  const effectiveIntensity: MaintenanceDecision =
    decision === "ALLOW" ? params.requestedIntensity : "low";
  return {
    decision,
    reasonCode: reasonCandidates[0] ?? "SAFE_TO_EXECUTE",
    effectiveIntensity,
  };
}

function buildPolicyHash(input: {
  policyId: string;
  decision: GuardrailDecision;
  reasonCode: string;
  requestedIntensity: MaintenanceDecision;
  effectiveIntensity: MaintenanceDecision;
  homeostasisMode: string;
  evaluationTrend: string;
  trusted: boolean;
}): string {
  return createHash("sha256").update(JSON.stringify(input)).digest("hex");
}

function emitMaintenancePolicyEvent(params: {
  scope: AeonStateScope;
  requestedIntensity: MaintenanceDecision;
  effectiveIntensity: MaintenanceDecision;
  reason: string;
  reasonCode: string;
  decision: GuardrailDecision;
  context: MaintenancePolicyContext;
  config: GuardrailRuntimeConfig;
}): void {
  const state = getAeonEvolutionState(params.scope);
  const scopeKey = getAeonScopeKey(params.scope);
  const now = Date.now();
  const policyId = "AEON_MAINTENANCE_GUARDRAIL_V1";
  const hash = buildPolicyHash({
    policyId,
    decision: params.decision,
    reasonCode: params.reasonCode,
    requestedIntensity: params.requestedIntensity,
    effectiveIntensity: params.effectiveIntensity,
    homeostasisMode: state.homeostasis.mode,
    evaluationTrend: state.evaluation.trend,
    trusted: state.ethics.trusted,
  });
  const previous = maintenancePolicyAuditStateByScope.get(scopeKey);
  const throttleMs = params.config.auditThrottleSeconds * 1000;
  const shouldHeartbeat = previous?.hash === hash && now - previous.lastLoggedAt >= throttleMs;
  const shouldEmit = !previous || previous.hash !== hash || shouldHeartbeat;

  if (!shouldEmit) {
    maintenancePolicyAuditStateByScope.set(scopeKey, {
      hash,
      lastLoggedAt: previous.lastLoggedAt,
      count: previous.count + 1,
    });
    return;
  }

  maintenancePolicyAuditStateByScope.set(scopeKey, {
    hash,
    lastLoggedAt: now,
    count: (previous?.count ?? 0) + 1,
  });

  void logEvolutionDecisionEvent({
    type: "AUTONOMOUS",
    title: shouldHeartbeat ? "Maintenance Policy Heartbeat" : "Maintenance Policy Decision",
    policyId,
    decision: params.decision,
    reasonCode: params.reasonCode,
    inputs: {
      epiphanyFactor: Number(params.context.epiphanyFactor.toFixed(4)),
      memorySaturation: params.context.memorySaturation,
      idleTimeMs: Math.max(0, Math.floor(params.context.idleTime)),
      resonanceTrigger: params.context.resonanceTrigger,
    },
    thresholds: {
      redlineBreachRisk: 0.65,
      minimumReady: true,
      ethicsTrusted: true,
      homeostasisMode: "balanced|explore",
    },
    actionTaken:
      params.effectiveIntensity === params.requestedIntensity
        ? `execute:${params.effectiveIntensity}`
        : `downgrade:${params.requestedIntensity}->${params.effectiveIntensity}`,
    rollbackHint: "Set aeon.guardrails.enforcementMode=soft for temporary downgrade-only mode.",
    scopeKey,
    heartbeat: shouldHeartbeat,
    details: [
      `Reason: ${params.reason}`,
      `Homeostasis mode: ${state.homeostasis.mode}`,
      `Evaluation trend: ${state.evaluation.trend}`,
      `Ethics trusted: ${state.ethics.trusted}`,
    ],
  });
}

export function resolveAutonomousMaintenancePolicy(params: {
  scope: AeonStateScope;
  context: MaintenancePolicyContext;
  config?: GuardrailRuntimeConfig;
}): AutonomousMaintenancePolicyResolution {
  const plan = resolveMaintenanceIntensity({
    epiphanyFactor: params.context.epiphanyFactor,
    memorySaturation: params.context.memorySaturation,
    idleTime: params.context.idleTime,
    resonanceTrigger: params.context.resonanceTrigger,
    scope: params.scope,
  });
  const config = params.config ?? resolveGuardrailConfig();
  const guardrail = evaluateGuardrailDecision({
    scope: params.scope,
    requestedIntensity: plan.intensity,
    context: params.context,
    config,
  });
  return { plan, guardrail };
}

async function runAeonMaintenance(
  intensity: MaintenanceDecision = "medium",
  scope?: AeonStateScope,
): Promise<void> {
  const now = Date.now();
  const scopeKey = getAeonScopeKey(scope);
  const lastMaintenanceAt = lastMaintenanceAtByScope.get(scopeKey) ?? 0;
  // Adjust interval based on intensity: high energy allows more frequent cycles
  const interval =
    intensity === "high"
      ? 15 * 60 * 1000
      : intensity === "medium"
        ? 45 * 60 * 1000
        : MAINTENANCE_INTERVAL_MS;
  if (now - lastMaintenanceAt < interval) {
    return;
  }
  lastMaintenanceAtByScope.set(scopeKey, now);
  lastMaintenanceAtInternal = now;

  log.info(`AEON maintenance: initiating ${intensity} intensity cycle.`);

  try {
    // Only medium/high intensity runs distillation
    if (intensity !== "low") {
      const distillResult = await distillMemory();
      if (distillResult.status === "success") {
        recordMemoryPersistence(
          {
            lastDistillAt: distillResult.lastDistillAt ?? Date.now(),
            checkpoint: distillResult.checkpoint ?? 0,
            totalEntries: distillResult.totalEntries ?? 0,
            lastWriteSource: distillResult.lastWriteSource ?? "maintenance",
          },
          scope,
        );
        recordAeonMaintenance(now, intensity, scope);
        log.info(
          `AEON maintenance: distilled memory -> ${distillResult.axiomsExtracted ?? 0} new axioms.`,
        );
        void logEvolutionEvent("SYSTEM_MAINTENANCE", `Autonomous Distillation (${intensity})`, [
          `Extracted ${distillResult.axiomsExtracted ?? 0} new axioms from MEMORY.md.`,
          `Maintenance intensity set to ${intensity}.`,
        ]);
      } else if (distillResult.status === "no-change") {
        const state = await readMemoryDistillState().catch(() => null);
        if (state) {
          recordMemoryPersistence(
            {
              lastDistillAt: state.lastDistillAt,
              checkpoint: state.checkpoint,
              totalEntries: state.totalEntries,
              lastWriteSource: state.lastWriteSource,
            },
            scope,
          );
        }
        log.debug("AEON maintenance: no new axioms to distill from MEMORY.md.");
      } else if (distillResult.error) {
        log.warn(`AEON maintenance: distillation error: ${distillResult.error}`);
      }
    }
  } catch (err) {
    log.warn(`AEON maintenance: distillation threw: ${String(err)}`);
  }

  try {
    const logicTool = createLogicRefinementTool();
    if (intensity === "low") {
      // Low energy: selective cluster audit (20% of Peano space)
      const start = Math.random() * 0.8;
      const result = (await logicTool.execute("evolution:audit", {
        action: "audit",
        peanoRange: [start, start + 0.2],
      })) as any;
      log.info(
        `AEON maintenance: selective logic audit performed on Peano range [${start.toFixed(2)}, ${(start + 0.2).toFixed(2)}]. Health: ${result.findings?.topologicalHealth ?? "N/A"}`,
      );
      void logEvolutionEvent("AUTONOMOUS", `Selective Peano Audit`, [
        `Range: [${start.toFixed(2)}, ${(start + 0.2).toFixed(2)}]`,
        `Intensity: low`,
        `Health: ${result.findings?.topologicalHealth ?? "N/A"}`,
      ]);
    } else {
      const auditResult = (await logicTool.execute("evolution:audit", { action: "audit" })) as any;
      if (intensity === "high") {
        const pruneResult = (await logicTool.execute("evolution:prune", {
          action: "prune",
        })) as any;
        log.info(
          `AEON maintenance: full logic audit and pruning completed (High-Energy). Pruned: ${pruneResult.prunedCount ?? 0}.`,
        );
      } else {
        log.info(
          `AEON maintenance: full logic audit completed. Health: ${auditResult.findings?.topologicalHealth ?? "N/A"}`,
        );
      }
      void logEvolutionEvent("AUTONOMOUS", `Full Logic Refinement (${intensity})`, [
        `Intensity: ${intensity}`,
        `Action: ${intensity === "high" ? "Audit + Prune" : "Audit"}`,
        `Health: ${auditResult.findings?.topologicalHealth ?? "N/A"}`,
      ]);
    }
  } catch (err) {
    log.warn(`AEON maintenance: logic refinement error: ${String(err)}`);
  }
}

async function triggerSingularityEvent(
  mainSession: any,
  mainSessionKey: string,
  factor: number,
): Promise<void> {
  log.warn(`!!! SINGULARITY EVENT TRIGGERED (Factor: ${factor.toFixed(2)}) !!!`);
  const scope: AeonStateScope = {
    sessionKey: mainSessionKey,
    agentId: resolveSessionAgentId({ sessionKey: mainSessionKey, config: loadConfig() }) ?? "main",
  };

  const { triggerAeonSingularity } = await import("./aeon-state.js");
  triggerAeonSingularity(true, scope);

  void logEvolutionEvent("SINGULARITY", "Cognitive Rebirth / 奇点重生", [
    `Extreme resonance detected: ${factor.toFixed(2)}`,
    `Initiating system-wide recursive logic refactor.`,
    `Peano space alignment: Phase Shift.`,
  ]);

  // Force high-intensity maintenance immediately
  await runAeonMaintenance("high", scope);

  // Trigger specialized heartbeat
  requestHeartbeatNow({
    reason: "singularity" as any,
    agentId: mainSession.sessionId,
    sessionKey: mainSessionKey,
    coalesceMs: 500,
  });

  // Reset after 30 seconds of intense evolution
  setTimeout(() => triggerAeonSingularity(false, scope), 30000);
}

/**
 * AEON Evolution Monitor
 * Periodically checks for system idleness and triggers "Dreaming" events.
 */
export function startEvolutionMonitor(): void {
  log.info("Evolution monitor started (30s pulse, 5m maintenance).");

  let highResonanceCount = 0;

  // --- High Frequency Visual Heartbeat (30s) ---
  setInterval(async () => {
    const cfg = loadConfig();
    try {
      const workspaceRoot = resolveWorkspaceRoot(cfg.agents?.defaults?.workspace);
      const [logicStat, memoryStat] = await Promise.all([
        fs.stat(path.join(workspaceRoot, "LOGIC_GATES.md")).catch(() => null),
        fs.stat(path.join(workspaceRoot, "MEMORY.md")).catch(() => null),
      ]);
      const memorySize = memoryStat?.size ?? 0;
      const memorySaturation = Math.min(100, Math.floor((memorySize / 51200) * 100));
      const depthPlaceholder = logicStat ? Math.floor(logicStat.size / 1000) : 5;

      const epiphanyFactor = calculateEpiphanyFactor(0, memorySaturation, depthPlaceholder);
      const scope: AeonStateScope = { sessionKey: "main", agentId: "main" };
      applyConsciousnessRuntimePolicy(scope);
      recordAeonEpiphanyFactor(epiphanyFactor, scope);
      recordConsciousnessPulse(
        {
          epiphanyFactor,
          memorySaturation,
          neuralDepth: depthPlaceholder,
          idleMs: 0,
          resonanceActive: epiphanyFactor > 0.85,
          activeRun: false,
          goalDrift: Math.max(0, 0.35 - epiphanyFactor * 0.2),
          reasoningBias: Math.max(0.05, 0.28 - depthPlaceholder / 100),
          selfCorrectionRate: Math.min(1, 0.45 + epiphanyFactor * 0.25),
          noveltySignal: epiphanyFactor,
          resourcePressure: Math.max(0.1, 1 - memorySaturation / 100),
          riskLoad: epiphanyFactor > 0.92 ? 0.55 : 0.25,
          environmentSignal: 0.6,
        },
        scope,
      );

      const { updateCollectiveResonance } = await import("./aeon-state.js");
      updateCollectiveResonance([epiphanyFactor], scope);
    } catch (e) {
      log.debug(`Heartbeat calculation skipped: ${String(e)}`);
    }
  }, 30 * 1000);

  // --- Maintenance & Singularity Cycle (5m) ---
  setInterval(
    async () => {
      const cfg = loadConfig();
      const mainSessionKey = resolveMainSessionKey(cfg);
      if (!mainSessionKey) return;

      try {
        const storeConfig = cfg.session?.store as any;
        const storePathStr = typeof storeConfig === "string" ? storeConfig : storeConfig?.path;
        const storePath = resolveStorePath(storePathStr);
        const store = loadSessionStore(storePath);
        const mainSession = store[mainSessionKey];
        if (!mainSession) return;

        const now = Date.now();
        const idleTime = now - mainSession.updatedAt;
        const scope: AeonStateScope = {
          sessionKey: mainSessionKey,
          agentId: resolveSessionAgentId({ sessionKey: mainSessionKey, config: cfg }) ?? "main",
        };
        applyConsciousnessRuntimePolicy(scope);
        const scopeKey = getAeonScopeKey(scope);

        // Extract current epiphany factor for singularity check
        const workspaceRoot = resolveWorkspaceRoot(cfg.agents?.defaults?.workspace);
        const [logicStat, memoryStat] = await Promise.all([
          fs.stat(path.join(workspaceRoot, "LOGIC_GATES.md")).catch(() => null),
          fs.stat(path.join(workspaceRoot, "MEMORY.md")).catch(() => null),
        ]);
        const memorySaturation = Math.min(100, Math.floor(((memoryStat?.size ?? 0) / 51200) * 100));
        const depthPlaceholder = logicStat ? Math.floor(logicStat.size / 1000) : 5;
        const epiphanyFactor = calculateEpiphanyFactor(
          idleTime > IDLE_THRESHOLD_MS ? 2 : 0,
          memorySaturation,
          depthPlaceholder,
        );

        // check for Singularity threshold
        if (epiphanyFactor > 0.95) {
          highResonanceCount++;
          if (highResonanceCount >= 2) {
            await triggerSingularityEvent(mainSession, mainSessionKey, epiphanyFactor);
            highResonanceCount = 0;
          }
        } else {
          highResonanceCount = 0;
        }

        const resonanceTrigger = epiphanyFactor > 0.85;
        recordConsciousnessPulse(
          {
            epiphanyFactor,
            memorySaturation,
            neuralDepth: depthPlaceholder,
            idleMs: Math.max(0, idleTime),
            resonanceActive: resonanceTrigger,
            activeRun: false,
            goalDrift: resonanceTrigger ? 0.22 : 0.32,
            reasoningBias: Math.max(0.05, 0.25 - depthPlaceholder / 120),
            selfCorrectionRate: resonanceTrigger ? 0.65 : 0.48,
            valueConflictLoad: resonanceTrigger ? 0.35 : 0.22,
            shortTermTemptation: resonanceTrigger ? 0.28 : 0.18,
            explanationQuality: Math.min(1, 0.4 + depthPlaceholder / 24),
            resourcePressure: clampMaintenanceResourcePressure(memorySaturation, idleTime),
            riskLoad: resonanceTrigger ? 0.5 : 0.22,
            noveltySignal: epiphanyFactor,
            failureCost: resonanceTrigger ? 0.55 : 0.28,
            socialFeedback: resonanceTrigger ? 0.65 : 0.45,
            environmentSignal: idleTime > IDLE_THRESHOLD_MS ? 0.42 : 0.7,
          },
          scope,
        );

        if (idleTime > IDLE_THRESHOLD_MS || resonanceTrigger) {
          const lastDreamingAt = lastDreamingAtByScope.get(scopeKey) ?? 0;
          if (now - lastDreamingAt > (resonanceTrigger ? 5 * 60 * 1000 : DREAMING_INTERVAL_MS)) {
            const reason = resonanceTrigger ? "resonance_epiphany" : "dreaming";
            log.info(
              `System ${resonanceTrigger ? "Resonance" : "Idle"} detected. Factor: ${epiphanyFactor.toFixed(2)}. Triggering ${reason}.`,
            );
            lastDreamingAtByScope.set(scopeKey, now);
            lastDreamingAtInternal = now;
            recordAeonDreaming(now, scope);

            requestHeartbeatNow({
              reason: reason as any,
              agentId: mainSession.sessionId,
              sessionKey: mainSessionKey,
              coalesceMs: resonanceTrigger ? 1000 : 5000,
            });

            const guardrailConfig = resolveGuardrailConfig();
            const { plan, guardrail } = resolveAutonomousMaintenancePolicy({
              scope,
              context: { epiphanyFactor, memorySaturation, idleTime, resonanceTrigger },
              config: guardrailConfig,
            });
            recordMaintenancePolicyDecision(
              {
                maintenanceDecision: guardrail.effectiveIntensity,
                guardrailDecision: guardrail.decision,
                reasonCode: guardrail.reasonCode,
              },
              scope,
            );
            log.debug(
              `Autonomous maintenance policy selected intensity=${plan.intensity} effective=${guardrail.effectiveIntensity} guardrail=${guardrail.decision} reason=${guardrail.reasonCode}`,
            );
            emitMaintenancePolicyEvent({
              scope,
              requestedIntensity: plan.intensity,
              effectiveIntensity: guardrail.effectiveIntensity,
              reason: plan.reason,
              reasonCode: guardrail.reasonCode,
              decision: guardrail.decision,
              context: { epiphanyFactor, memorySaturation, idleTime, resonanceTrigger },
              config: guardrailConfig,
            });
            void runAeonMaintenance(guardrail.effectiveIntensity, scope);
          }
        } else if (
          epiphanyFactor < 0.2 &&
          now - (lastMaintenanceAtByScope.get(scopeKey) ?? 0) > MAINTENANCE_INTERVAL_MS
        ) {
          const guardrailConfig = resolveGuardrailConfig();
          const { plan, guardrail } = resolveAutonomousMaintenancePolicy({
            scope,
            context: { epiphanyFactor, memorySaturation, idleTime, resonanceTrigger },
            config: guardrailConfig,
          });
          recordMaintenancePolicyDecision(
            {
              maintenanceDecision: guardrail.effectiveIntensity,
              guardrailDecision: guardrail.decision,
              reasonCode: guardrail.reasonCode,
            },
            scope,
          );
          emitMaintenancePolicyEvent({
            scope,
            requestedIntensity: plan.intensity,
            effectiveIntensity: guardrail.effectiveIntensity,
            reason: plan.reason,
            reasonCode: guardrail.reasonCode,
            decision: guardrail.decision,
            context: { epiphanyFactor, memorySaturation, idleTime, resonanceTrigger },
            config: guardrailConfig,
          });
          void runAeonMaintenance(guardrail.effectiveIntensity, scope);
        }

        const { matrix } = await import("./collective-consciousness.js");
        matrix.cleanup(3600000);
      } catch (err) {
        log.error(`Maintenance cycle error: ${String(err)}`);
      }
    },
    5 * 60 * 1000,
  );
}
