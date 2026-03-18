import fs from "node:fs/promises";
import path from "node:path";
import { resolveStateDir } from "../config/paths.js";

export type DeliveryState =
  | "running"
  | "finalizing"
  | "persisted"
  | "acknowledged"
  | "persist_failed";

export type DeliveryRecord = {
  runId: string;
  sessionKey: string;
  state: DeliveryState;
  updatedAt: number;
  persistedAt?: number;
  reasonCode?: string;
  taskGoal?: string;
  summary?: string;
  artifactRefs?: string[];
};

const DELIVERY_LOG_PATH = path.join(resolveStateDir(), "aeon", "delivery", "events.jsonl");
const MAX_LOOKUP_LIMIT = 200;

function normalizeArtifactRefs(refs: string[] | undefined): string[] {
  if (!Array.isArray(refs)) {
    return [];
  }
  return refs
    .map((entry) => (typeof entry === "string" ? entry.trim() : ""))
    .filter((entry) => entry.length > 0)
    .slice(0, 32);
}

function parseRecord(line: string): DeliveryRecord | null {
  try {
    const parsed = JSON.parse(line) as Partial<DeliveryRecord>;
    if (
      typeof parsed.runId !== "string" ||
      typeof parsed.sessionKey !== "string" ||
      typeof parsed.state !== "string" ||
      typeof parsed.updatedAt !== "number"
    ) {
      return null;
    }
    return {
      runId: parsed.runId,
      sessionKey: parsed.sessionKey,
      state: parsed.state as DeliveryState,
      updatedAt: parsed.updatedAt,
      persistedAt:
        typeof parsed.persistedAt === "number" && Number.isFinite(parsed.persistedAt)
          ? parsed.persistedAt
          : undefined,
      reasonCode: typeof parsed.reasonCode === "string" ? parsed.reasonCode : undefined,
      taskGoal: typeof parsed.taskGoal === "string" ? parsed.taskGoal : undefined,
      summary: typeof parsed.summary === "string" ? parsed.summary : undefined,
      artifactRefs: normalizeArtifactRefs(parsed.artifactRefs),
    };
  } catch {
    return null;
  }
}

async function readAllRecords(): Promise<DeliveryRecord[]> {
  try {
    const raw = await fs.readFile(DELIVERY_LOG_PATH, "utf-8");
    return raw
      .split("\n")
      .map((line) => line.trim())
      .filter(Boolean)
      .map(parseRecord)
      .filter((entry): entry is DeliveryRecord => entry !== null);
  } catch {
    return [];
  }
}

export async function recordDeliveryTransition(
  record: Omit<DeliveryRecord, "updatedAt"> & { updatedAt?: number },
): Promise<void> {
  const entry: DeliveryRecord = {
    runId: record.runId.trim(),
    sessionKey: record.sessionKey.trim(),
    state: record.state,
    updatedAt: record.updatedAt ?? Date.now(),
    persistedAt: record.persistedAt,
    reasonCode: record.reasonCode,
    taskGoal: record.taskGoal?.trim() || undefined,
    summary: record.summary?.trim() || undefined,
    artifactRefs: normalizeArtifactRefs(record.artifactRefs),
  };
  if (!entry.runId || !entry.sessionKey) {
    return;
  }
  await fs.mkdir(path.dirname(DELIVERY_LOG_PATH), { recursive: true });
  await fs.appendFile(DELIVERY_LOG_PATH, JSON.stringify(entry) + "\n", "utf-8");
}

function latestByRun(records: DeliveryRecord[]): DeliveryRecord[] {
  const latest = new Map<string, DeliveryRecord>();
  for (const entry of records) {
    const prev = latest.get(entry.runId);
    if (!prev || entry.updatedAt >= prev.updatedAt) {
      latest.set(entry.runId, entry);
    }
  }
  return Array.from(latest.values()).sort((a, b) => b.updatedAt - a.updatedAt);
}

export async function lookupDeliveryRecords(params?: {
  runId?: string;
  sessionKey?: string;
  limit?: number;
}): Promise<DeliveryRecord[]> {
  const records = latestByRun(await readAllRecords());
  const runId = params?.runId?.trim();
  const sessionKey = params?.sessionKey?.trim();
  const limit = Math.max(1, Math.min(MAX_LOOKUP_LIMIT, params?.limit ?? 50));
  return records
    .filter(
      (entry) =>
        (!runId || entry.runId === runId) && (!sessionKey || entry.sessionKey === sessionKey),
    )
    .slice(0, limit);
}

export async function recoverIncompleteDeliveries(): Promise<void> {
  const latest = latestByRun(await readAllRecords());
  const now = Date.now();
  const pending = latest.filter(
    (entry) => entry.state === "running" || entry.state === "finalizing",
  );
  if (pending.length === 0) {
    return;
  }
  await Promise.all(
    pending.map((entry) =>
      recordDeliveryTransition({
        runId: entry.runId,
        sessionKey: entry.sessionKey,
        state: "persist_failed",
        reasonCode: "RECOVERED_AFTER_RESTART",
        updatedAt: now,
      }),
    ),
  );
}

export function extractArtifactRefs(text: string | undefined): string[] {
  if (!text) {
    return [];
  }
  const refs = new Set<string>();
  const unixAbs = /(?:^|\s)(\/[A-Za-z0-9._\-/]+(?:\.[A-Za-z0-9._-]+)?)/g;
  const winAbs = /(?:^|\s)([A-Za-z]:\\[A-Za-z0-9._\-\\ ]+(?:\.[A-Za-z0-9._-]+)?)/g;
  let match: RegExpExecArray | null;
  while ((match = unixAbs.exec(text))) {
    const value = match[1]?.trim();
    if (value && value.length > 1) {
      refs.add(value);
    }
  }
  while ((match = winAbs.exec(text))) {
    const value = match[1]?.trim();
    if (value && value.length > 2) {
      refs.add(value);
    }
  }
  return Array.from(refs).slice(0, 16);
}
