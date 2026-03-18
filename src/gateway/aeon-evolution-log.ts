import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { resolveStateDir } from "../config/paths.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, "../../");
const LOG_FILE_PATH = path.join(REPO_ROOT, "docs/aeon/EVOLUTION.md");
const FALLBACK_LOG_FILE_PATH = path.join(resolveStateDir(), "logs", "aeon", "EVOLUTION.md");

async function appendEvolutionLog(filePath: string, entry: string): Promise<void> {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.appendFile(filePath, entry, "utf-8");
}

/**
 * Logs a significant evolutionary event to docs/aeon/EVOLUTION.md
 */
export async function logEvolutionEvent(
  type: "AUTONOMOUS" | "HUMAN_LED" | "SYSTEM_MAINTENANCE" | "SINGULARITY",
  title: string,
  details: string[],
): Promise<void> {
  const timestamp = new Date().toISOString().replace("T", " ").split(".")[0];
  const entry = `
## ${timestamp} [${type}_EVOLUTION]
**Status**: ${title}
**Details**:
${details.map((d) => `- ${d}`).join("\n")}
`;

  try {
    await appendEvolutionLog(LOG_FILE_PATH, entry);
  } catch (err) {
    try {
      if (path.resolve(FALLBACK_LOG_FILE_PATH) !== path.resolve(LOG_FILE_PATH)) {
        await appendEvolutionLog(FALLBACK_LOG_FILE_PATH, entry);
        console.warn(
          `Evolution log fallback active: primary=${LOG_FILE_PATH} fallback=${FALLBACK_LOG_FILE_PATH}`,
        );
        return;
      }
    } catch (fallbackErr) {
      console.error(
        `Failed to write to evolution log: primary=${String(err)} fallback=${String(fallbackErr)}`,
      );
      return;
    }
    console.error(`Failed to write to evolution log: ${String(err)}`);
  }
}

export type EvolutionDecisionEvent = {
  type: "AUTONOMOUS" | "HUMAN_LED" | "SYSTEM_MAINTENANCE" | "SINGULARITY";
  title: string;
  policyId: string;
  decision: "ALLOW" | "SOFT_WARN" | "BLOCK";
  reasonCode: string;
  inputs: Record<string, string | number | boolean | null>;
  thresholds: Record<string, string | number | boolean | null>;
  actionTaken: string;
  rollbackHint?: string;
  scopeKey?: string;
  heartbeat?: boolean;
  details?: string[];
};

export async function logEvolutionDecisionEvent(event: EvolutionDecisionEvent): Promise<void> {
  const details = [
    `Policy ID: ${event.policyId}`,
    `Decision: ${event.decision}`,
    `Reason Code: ${event.reasonCode}`,
    `Action Taken: ${event.actionTaken}`,
    ...(event.scopeKey ? [`Scope: ${event.scopeKey}`] : []),
    ...(event.heartbeat ? ["Heartbeat: true"] : []),
    ...(event.rollbackHint ? [`Rollback Hint: ${event.rollbackHint}`] : []),
    `Inputs: ${JSON.stringify(event.inputs)}`,
    `Thresholds: ${JSON.stringify(event.thresholds)}`,
    ...(event.details ?? []),
  ];
  await logEvolutionEvent(event.type, event.title, details);
}
